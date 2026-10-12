# Task: API đăng ký & đăng nhập (JWT)

## Mục tiêu
Thiết kế + implement 2 API đầu tiên của hệ thống: đăng ký account và đăng nhập, trả về JWT token. Chuẩn REST, có versioning, dùng đúng convention sẵn có của project (Jbuilder, `ApplicationController`).

## Routes

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resource :registration, only: :create
    post "login", to: "sessions#create"
  end
end
```

| Method | Path | Action |
|---|---|---|
| POST | `/api/v1/registration` | Đăng ký user mới |
| POST | `/api/v1/login` | Đăng nhập, trả JWT |

## Files cần tạo

- `Gemfile` → thêm `gem "jwt"`, `bundle install`
- `app/lib/json_web_token.rb` — utility encode/decode JWT (pure, không biết gì về `User`)
- `app/controllers/api/v1/base_controller.rb` — base controller cho API v1
- `app/controllers/api/v1/registrations_controller.rb`
- `app/controllers/api/v1/sessions_controller.rb`
- `app/views/api/v1/sessions/create.json.jbuilder` (registration chỉ render message đơn giản, không cần jbuilder view riêng)

## Chi tiết implementation

### `app/lib/json_web_token.rb`
```ruby
module JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    ActiveSupport::HashWithIndifferentAccess.new(decoded)
  end
end
```

### `app/models/user.rb` (đã có sẵn, không đổi)
`set_jti` (sinh UUID lúc tạo user) đã có từ trước. Có sẵn method để revoke token sau này (dùng ở `/logout` hoặc khi đổi password — nằm ngoài phạm vi 2 API hiện tại):
```ruby
def regenerate_jti!
  update!(jti: SecureRandom.uuid)
end
```

### `app/controllers/application_controller.rb`
`rescue_from` cho `ActionController::ParameterMissing` đặt ở đây (base chung của cả app), không đặt riêng ở `Api::V1::BaseController` — để áp dụng nhất quán cho mọi version API sau này (`v2`...), không phải khai báo lại mỗi version:
```ruby
class ApplicationController < ActionController::Base
  # ...
  rescue_from ActionController::ParameterMissing do |e|
    render json: { errors: ["#{e.param.to_s.humanize} is required"] }, status: :bad_request
  end
end
```
Dùng `e.param` (tên field bị thiếu) để build message thân thiện (`"Password is required"`) thay vì message mặc định dài dòng của Rails (`"param is missing or the value is empty: password"`).

### `app/controllers/api/v1/base_controller.rb`
```ruby
class Api::V1::BaseController < ApplicationController
  wrap_parameters false
  skip_before_action :verify_authenticity_token, raise: false
end
```

### `app/controllers/api/v1/registrations_controller.rb`
```ruby
class Api::V1::RegistrationsController < Api::V1::BaseController
  def create
    @user = User.new(user_params)

    if @user.save
      render json: { user: { id: @user.id, email: @user.email, name: @user.name } }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:email)
    params.require(:password)
    params.permit(:email, :password, :name)
  end
end
```

### `app/controllers/api/v1/sessions_controller.rb`
```ruby
class Api::V1::SessionsController < Api::V1::BaseController
  def create
    @user = User.find_by(email: login_params[:email]&.downcase)

    if @user&.authenticate(login_params[:password])
      @token = JsonWebToken.encode(user_id: @user.id, jti: @user.jti)
      render :create, status: :ok
    else
      render json: { errors: ["Invalid email or password"] }, status: :unauthorized
    end
  end

  private

  def login_params
    params.require(:email)
    params.require(:password)
    params.permit(:email, :password)
  end
end
```

### `app/views/api/v1/sessions/create.json.jbuilder`
```ruby
json.user do
  json.id @user.id
  json.email @user.email
  json.name @user.name
end
json.token @token
```

## Phân tầng status code (chuẩn Rails-only API)

| Status | Ý nghĩa | Khi nào |
|---|---|---|
| **400 Bad Request** | Request sai cấu trúc — thiếu field bắt buộc, JSON malformed | `params.require` raise `ParameterMissing` (rescue ở `ApplicationController`); JSON sai cú pháp thì Rails tự trả 400 |
| **401 Unauthorized** | Sai thông tin xác thực | Login sai email/password |
| **422 Unprocessable Entity** | Đúng cấu trúc nhưng vi phạm business rule | Email đã tồn tại, password quá ngắn |

## Request / Response contract

**POST /api/v1/registration**
```json
// request
{ "email": "a@b.com", "password": "12345678", "name": "Viet" }

// 201 Created
{ "user": { "id": 1, "email": "a@b.com", "name": "Viet" } }

// 400 Bad Request (thiếu email hoặc password)
{ "errors": ["Password is required"] }

// 422 Unprocessable Entity (đúng cấu trúc nhưng vi phạm business rule)
{ "errors": ["Email has already been taken"] }
```

**POST /api/v1/login**
```json
// request
{ "email": "a@b.com", "password": "12345678" }

// 200 OK
{ "user": { "id": 1, "email": "a@b.com", "name": "Viet" }, "token": "eyJ..." }

// 400 Bad Request (thiếu email hoặc password)
{ "errors": ["Email is required"] }

// 401 Unauthorized (sai credential)
{ "errors": ["Invalid email or password"] }
```

## Quyết định thiết kế (và lý do)

- **Versioning `/api/v1`**: cho phép sau này đổi breaking change mà không phá API cũ của client đang dùng.
- **Login đặt path `/login` nhưng controller vẫn là `SessionsController`**: đúng bản chất REST (login = tạo session), nhưng path dễ hiểu hơn cho người dùng API.
- **Jbuilder thay vì PORO serializer**: đã có sẵn trong Gemfile, là convention mặc định của Rails — không cần thêm abstraction mới.
- **JWT logic đặt ở `app/lib`, không phải `app/services`**: encode/decode là utility thuần (pure function), không biết gì về domain `User` — không phải business use-case nên chưa cần service object. Khi logic đăng ký/login phức tạp hơn mới tách `app/services/`.
- **Token có `jti`**: payload gồm `user_id`, `jti`, `exp`. `jti` là UUID sinh sẵn trên `User` (cột đã có từ trước), nhúng vào token lúc encode. Cho phép revoke token chủ động sau này (đổi password, logout "tất cả thiết bị", khóa tài khoản) bằng cách gọi `user.regenerate_jti!` — token cũ cầm `jti` khác sẽ bị middleware từ chối dù chưa hết hạn. 2 API hiện tại (register/login) chỉ cần **sinh** token kèm `jti`; việc **verify** `jti` khi request vào API được bảo vệ thuộc về middleware `authenticate_request` (xem phần Ngoài phạm vi).
- **Request body dùng flat JSON, không nest theo `user:`/`session:`**: giống style của đa số public API thực tế (Stripe, GitHub, Auth0, Firebase...) — nested key chủ yếu còn lại từ convention Rails form HTML (`form_with model:`), không cần thiết cho API JSON thuần. `params.permit` dùng trực tiếp, không `params.require(:user)`.
- **Lỗi login luôn generic** ("Invalid email or password"): không tiết lộ email có tồn tại hay không, tránh user enumeration.
- **`password_digest` không bao giờ lộ ra response**: chỉ chọn đúng field cần trả (`id`, `email`, `name`).
- **Phân tầng 400/401/422 rõ ràng**: `params.require(:email)` + `params.require(:password)` trong `user_params`/`login_params` để chủ động raise `ActionController::ParameterMissing` khi thiếu field bắt buộc → rescue ở `ApplicationController` (dùng chung toàn app, không lặp lại ở từng API version) → trả 400. Business rule validation (uniqueness, length...) vẫn ở tầng model → 422. Sai credential → 401. Không gộp chung các case này vào 1 status code.
- **Registration không trả JWT**: đăng ký xong chỉ trả thông tin user, không auto-login kèm token — user phải gọi `/login` riêng. Giữ 2 bước tách biệt cho đơn giản, dễ test/deploy production trước, không phụ thuộc thêm bước email verification nào.

## Ngoài phạm vi (làm sau)
- Middleware `authenticate_request`/`current_user` để bảo vệ API khác bằng JWT — sẽ verify `jti` trong token khớp với `user.jti` hiện tại trong DB (nếu khác → token đã bị revoke, trả `401`).
- API `/logout` gọi `user.regenerate_jti!` để vô hiệu hóa token hiện tại.
- Email verification, refresh token, rate limiting, password reset.
- Liên kết đăng ký với tạo `Store` mặc định (nếu cần).

## Checklist implement
- [x] Thêm `gem "jwt"` vào Gemfile, bundle install
- [x] Thêm routes `registration` và `login`
- [x] Viết `JsonWebToken` lib
- [x] Viết `Api::V1::BaseController`
- [x] Viết `RegistrationsController` (không trả token)
- [x] Viết `SessionsController` + jbuilder view
- [x] Viết integration test cho 2 API (`test/controllers/api/v1/`), chạy trên database test
- [x] Phân tầng 400 (thiếu field)/401 (sai credential)/422 (vi phạm business rule), rescue `ParameterMissing` ở `ApplicationController`
