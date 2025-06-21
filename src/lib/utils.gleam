pub fn list_is_empty(of: List(a)) -> Bool {
  of == []
}

pub fn list_is_present(of: List(a)) -> Bool {
  !list_is_empty(of)
}
