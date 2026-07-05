import { Controller } from "@hotwired/stimulus"

// タグのチップ入力UI。
// テキスト入力で Enter またはカンマを打つとチップが追加され、
// 各チップに hidden input（name="...[]"）を持たせて配列としてPOSTする。
export default class extends Controller {
  static targets = ["chips", "input"]
  static values = { name: String }

  add(event) {
    if (event.key !== "Enter" && event.key !== ",") return
    event.preventDefault()
    this.commit()
  }

  // フォーム送信前など、未確定の入力を取りこぼさないよう blur でも確定する。
  blur() {
    this.commit()
  }

  commit() {
    const value = this.inputTarget.value.trim().replace(/,+$/, "")
    if (value === "") return
    if (this.existingValues().includes(value)) {
      this.inputTarget.value = ""
      return
    }
    this.chipsTarget.insertBefore(this.buildChip(value), this.inputTarget)
    this.inputTarget.value = ""
  }

  remove(event) {
    event.target.closest("[data-chip]").remove()
  }

  existingValues() {
    return Array.from(
      this.chipsTarget.querySelectorAll("input[type=hidden]")
    ).map((input) => input.value)
  }

  buildChip(value) {
    const chip = document.createElement("span")
    chip.dataset.chip = ""
    chip.className =
      "inline-flex items-center gap-1 rounded-full bg-chip px-3 py-1 text-[13px] text-text-primary"

    const hidden = document.createElement("input")
    hidden.type = "hidden"
    hidden.name = this.nameValue
    hidden.value = value

    const label = document.createElement("span")
    label.textContent = value

    const button = document.createElement("button")
    button.type = "button"
    button.textContent = "×"
    button.className = "text-text-muted"
    button.dataset.action = "chip-input#remove"

    chip.append(hidden, label, button)
    return chip
  }
}
