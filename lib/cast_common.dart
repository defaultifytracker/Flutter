T tryCast<T>(dynamic x, T fallback) {
  try {
    return (x as T);
    // ignore: unused_catch_clause
  } on TypeError catch (e) {
    return fallback;
  }
}
