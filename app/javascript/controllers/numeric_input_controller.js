import { Controller } from "@hotwired/stimulus"

// 非負整数だけを入力させるためのガード。
// type="number" は min/step があっても "-" "." "e" などの打鍵を防げないため、
// 0〜9 以外の文字キーはすべてブロックし、そのタイミングでエラーメッセージを表示する。
// 貼り付け等の抜け道は input で数字以外を除去する。
export default class extends Controller {
  static targets = ["input", "message"]

  keydown(event) {
    // Ctrl/Cmd/Alt 併用（コピペ・全選択など）は許可する
    if (event.ctrlKey || event.metaKey || event.altKey) return
    // Backspace, Tab, 矢印, Enter などの制御キー（キー名が2文字以上）は許可する
    if (event.key.length > 1) return

    // 1文字キーで 0〜9 以外ならブロックしてエラー表示
    if (!/[0-9]/.test(event.key)) {
      event.preventDefault()
      this.showError()
    }
  }

  sanitize() {
    const digitsOnly = this.inputTarget.value.replace(/[^0-9]/g, "")
    if (this.inputTarget.value !== digitsOnly) {
      this.inputTarget.value = digitsOnly
      this.showError()
    } else {
      this.hideError()
    }
  }

  showError() {
    if (this.hasMessageTarget) this.messageTarget.classList.remove("hidden")
    this.inputTarget.classList.add("mh-input-error")
    this.inputTarget.setAttribute("aria-invalid", "true")
  }

  hideError() {
    if (this.hasMessageTarget) this.messageTarget.classList.add("hidden")
    this.inputTarget.classList.remove("mh-input-error")
    this.inputTarget.setAttribute("aria-invalid", "false")
  }
}
