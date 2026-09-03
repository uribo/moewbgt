####################################
# 環境省 熱中症予防情報サイト WebAPI 仕様書 (PDF) の取得
#
# 2026年度に追加された WebAPI の仕様書。引数・返り値の定義に加えて、
# 2-1節に JMA系の地方コード・都道府県コード一覧 (pref_cd) を持つ。
# TODO #4 (WebAPIクライアント) の設計元であり、pref_cd 対応表の抽出元。
#
# ここでは PDF を取得するところまでを行う。データセットはまだ作らない
# ので usethis::use_data() は呼んでいない。対応表を抽出する段になったら
# pdftools::pdf_text() の処理をこの下に足す。
#
# 上流の URL は2系統ある (2026-09-03 確認)。
# - 版なし … 現行版を指す「動く」URL。新しい版が出れば中身が入れ替わる
# - 日付入り … 掲載日を含む URL。第1.0版 (_r080422) はここから取れるが、
#   現行の第1.1版に対応する _r080624 は存在しない。日付入りの複製は
#   現行版ではなく旧版に対して作られている (差し替え時にアーカイブされる)
#   ように見える。第1.2版が出た時点で _r080624 が現れるかは要確認
####################################

api_manual_base <- "https://www.wbgt.env.go.jp/man15NH/"

# stable = TRUE は日付入りの URL で、中身が入れ替わらない前提。
# stable = FALSE は現行版を指す「動く」URL。
df_api_manuals <-
  tibble::tribble(
    ~version                                                           , ~file , ~stable , ~sha256 ,
    "1.1"                                                              ,
    "wbgt_data_api_service_manual.pdf"                                 ,
    FALSE                                                              ,
    "a29848c1fdab3d756261f548601741cadf8973c05fe2e6d0754fd2b4efdbc105" ,
    "1.0"                                                              ,
    "wbgt_data_api_service_manual_r080422.pdf"                         ,
    TRUE                                                               ,
    "18b35833db0ec2651d3201f69b8484602826caf40516c597b281052d624745ed"
  )

df_api_manuals |>
  purrr::pwalk(
    function(version, file, stable, sha256) {
      path <- here::here("data-raw", file)
      # 既にあるファイルは上書きしない (moe_wbgt_stations.R と同じガード)
      if (!file.exists(path)) {
        download.file(
          paste0(api_manual_base, file),
          destfile = path,
          mode = "wb"
        )
      }
      # 上流の差し替え・手元の破損を fail-loud で拾う。記録値の書き換えで
      # 黙らせない。動く URL 側が止まったら新しい版が出た可能性があるので、
      # PROVENANCE.md の版・掲載日・sha256 を更新し、README.md の仕様の
      # 記述も読み直す。日付入り URL 側が止まったのは異常事態である
      observed <- digest::digest(path, algo = "sha256", file = TRUE)
      if (!identical(observed, sha256)) {
        stop(
          glue::glue(
            "API仕様書 PDF (第{version}版) の sha256 が記録値と一致しない。\n",
            "  path:     {path}\n",
            "  expected: {sha256}\n",
            "  observed: {observed}\n",
            if (stable) {
              "日付入りの URL は中身が変わらない前提なので、これは異常。"
            } else {
              "上流が新しい版に差し替わった可能性がある。"
            },
            "\nPROVENANCE.md 「上流の状況」の節を参照。"
          )
        )
      }
    }
  )
