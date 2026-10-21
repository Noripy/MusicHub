# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    # Inter フォント（Google Fonts）だけを外部から許可する
    policy.font_src    :self, "https://fonts.gstatic.com"
    policy.style_src   :self, "https://fonts.googleapis.com"
    policy.img_src     :self, :data
    policy.script_src  :self
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self
    policy.frame_ancestors :none
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # まずは違反をブラウザのコンソールに出すだけにして、画面が壊れないことを確認してから強制する。
  config.content_security_policy_report_only = true
end
