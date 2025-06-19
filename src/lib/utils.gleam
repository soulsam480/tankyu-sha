pub fn list_empty(of: List(a)) -> Bool {
  of == []
}

pub fn list_present(of: List(a)) -> Bool {
  !list_empty(of)
}
