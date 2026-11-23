class_name Palette
extends RefCounted
## Bảng màu hệ "Cooked". Dùng để đặt màu trong code thay vì hardcode hex.
## Tham chiếu: Palette.HIGHLIGHT, Palette.SURFACE, ...
## Chi tiết & quy tắc dùng: xem assets/Style/palette.md

const HIGHLIGHT := Color("#F0A13E")  # accent (cam) — mọi thứ bấm được / nhấn mạnh
const SURFACE   := Color("#2F5D50")  # phụ (xanh rêu) — panel, khung card
const BACKGROUND := Color("#1C1F24") # nền tối
const TEXT      := Color("#F5EAD6")  # chữ kem
const DANGER    := Color("#C0392B")  # cảnh báo (đỏ) — boss, mất tiền, xóa
const DISABLED  := Color("#8C877C") # mờ / tắt
