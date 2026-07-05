module ApplicationHelper
  # フィールド直下に表示するインラインのバリデーションエラー（HTMLネイティブ検証風）。
  # 属性ごとに最初のエラーメッセージのみを簡潔に表示する。
  def field_error(record, attribute)
    message = record.errors[attribute].first
    return if message.blank?

    tag.p(message, class: "mh-error", id: field_error_id(record, attribute))
  end

  # エラーがあれば入力欄に赤枠クラスを付与する。
  def input_error_class(record, attribute)
    "mh-input-error" if record.errors[attribute].present?
  end

  # 入力欄と aria-describedby で紐づけるためのエラー要素 id。
  def field_error_id(record, attribute)
    "#{record.model_name.param_key}_#{attribute}_error"
  end
end
