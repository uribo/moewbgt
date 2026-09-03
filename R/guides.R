# wbgt_guideline(31)
# wbgt_guideline(30)
# wbgt_guideline(25)
# wbgt_guideline(18)
wbgt_guideline <- function(x, lang = "ja") {
  lang <-
    rlang::arg_match(lang, c("ja", "en"))
  l <-
    list(
      ja = c(
        "\u5371\u967a",
        "\u53b3\u91cd\u8b66\u6212",
        "\u8b66\u6212",
        "\u6ce8\u610f"
      ),
      en = c(
        "Danger",
        "Severe Warning",
        "Warning",
        "Caution"
      )
    )
  l <-
    switch(lang, "ja" = l$ja, "en" = l$en)

  # The bands of the guideline are half-open: 31 and above, 28 to 31, 25 to 28,
  # below 25. Expressing the middle two with between(x, 28, 30) leaves 30 < x
  # < 31 and 27 < x < 28 matching no condition at all, so wbgt_guideline(30.5)
  # returned NA. case_when() evaluates in order, so a descending chain of >=
  # covers the line without gaps. Keep the final `x < 25` rather than a
  # .default so that NA input still yields NA.
  dplyr::case_when(
    x >= 31 ~ l[[1]],
    x >= 28 ~ l[[2]],
    x >= 25 ~ l[[3]],
    x < 25 ~ l[[4]]
  )
}
