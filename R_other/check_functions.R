library(devtools)
check()
document()
check()
install()

load_all()


df <- xls_read("inst/extdata/aci-curve.xlsx")

fit_df <- fitaci(df, theta = 1.2, alpha = 1)

plot(fit_df)
