skip_if_no_dedupe <- function() {
  have_dedupe <- reticulate::py_module_available("dedupe")
  if (!have_dedupe) {
    skip("dedupe python module not available for testing")
  }
}

