#' Fit multiple A-Ci curves at once
#' 
#' @description A convenient function to fit many curves at once, by calling \code{\link{fitaci}} for 
#' every group in the dataset. The data provided must include a variable that uniquely identifies each A-Ci curve.
#' 
#' @param data Dataframe with Ci, Photo, Tleaf, PPFD (the last two are optional). For \code{fitacis}, 
#' also requires a grouping variable.
#' @param group The name of the grouping variable in the dataframe (an A-Ci curve will be fit for each group separately).
#' @param fitmethod Method to fit the A-Ci curve. Either 'default' (Duursma 2015), or 'bilinear'. See Details.
#' @param progressbar Display a progress bar (default is TRUE).
#' @param quiet If TRUE, no messages are written to the screen.
#' @param id Names of variables (quoted, can be a vector) in the original dataset to return as part of 
#' the coef() statement. Useful for keeping track of species names, treatment levels, etc. See Details and Examples.
#' @param x For \code{plot.acifits}, an object returned from \code{fitacis}
#' @param xlim,ylim The X and Y axis limits.
#' @param add If TRUE, adds the plots to a current plot.
#' @param how If 'manyplots', produces a single plot for each A-Ci curve. If 'oneplot' overlays all of them.
#' @param highlight If a name of a curve is given (check names(object), where object is returned by acifits), 
#' all curves are plotted in grey, with the highlighted one on top.
#' @param linecol Colour(s) to use for the non-highlighted curves (can be a vector).
#' @param linecol_highlight Colour to use for the 'highlighted' curve.
#' @param lty Line type(s), can be a vector (one for each level of the factor, will be recycled).
#' @param colour_by_id If TRUE, uses the 'id' argument to colour the curves in the standard plot (only works when \code{how = 'oneplot'}, see Examples)
#' @param id_legend If \code{colour_by_id} is set, place a legend (topleft) or not.
#' @param what What to plot, either 'model' (the fitted curve), 'data' or 'none'. See examples.
#' @param \dots Further arguments passed to \code{\link{fitaci}} (in the case of \code{fitacis}), or 
#' \code{\link{plot.acifit}} (in the case of \code{plot.acifits}).
#' 
#' @details 
#' \strong{Troubleshooting - } When using the default fitting method (see \code{\link{fitaci}}), it is common that 
#' some curves cannot be fit. Usually this indicates that the curve is poor quality and should not be used to 
#' estimate photosynthetic capacity, but there are exceptions. The \code{fitacis} function now refits the 
#' non-fitting curves with the 'bilinear' method (see \code{fitaci}), which will always return parameter estimates 
#' (for better or worse).
#' 
#' \strong{Summarizing and plotting - } Like \code{fitaci}, the batch utility \code{fitacis} also has a standard 
#' plotting method. By default, it will make a single plot for every curve that you fit (thus generating many plots). 
#' Alternatively, use the setting \code{how="oneplot"} (see Examples below) for a single plot. The fitted 
#' \strong{coefficients} are extracted with \code{coef}, which gives a dataframe where each row represents 
#' a fitted curve (the grouping label is also included).
#' 
#' \strong{Adding identifying variables - } after fitting multiple curves, the most logical next step is to 
#' analyze the coefficient by some categorical variable (species, treatment, location). You can use the 
#' \code{id} argument to store variables from the original dataset in the output. It is important that the 
#' 'id' variables take only one value per fitted curve, if this is not the case only the first value of the 
#' curve will be stored (this will be rarely useful). See examples.
#' 
#' @references 
#' Duursma, R.A., 2015. Plantecophys - An R Package for Analysing and Modelling Leaf Gas Exchange Data. 
#' PLoS ONE 10, e0143346. doi:10.1371/journal.pone.0143346
#' 
#' @examples
#' 
#' \dontrun{
#' # Fit many curves (using an example dataset)
#' # The bilinear method is much faster, but compare using 'default'!
#' fits <- fitacis(manyacidat, "Curve", fitmethod="bilinear")
#' with(coef(fits), plot(Vcmax, Jmax))
#' 
#' # The resulting object is a list, with each component an object as returned by fitaci
#' # So, we can extract one curve:
#' fits[[1]]
#' plot(fits[[1]])
#' 
#' # Plot all curves in separate figures with plot(fits)
#' # Or, in one plot:
#' plot(fits, how="oneplot")
#' 
#' # Note that parameters can be passed to plot.acifit. For example,
#' plot(fits, how="oneplot", what="data", col="blue")
#' plot(fits, how="oneplot", add=TRUE, what="model", lwd=c(1,1))
#' 
#' # Other elements can be summarized with sapply. For example, look at the RMSE:
#' rmses <- sapply(fits, "[[", "RMSE")
#' plot(rmses, type='h', ylab="RMSE", xlab="Curve nr")
#' 
#' # And plot the worst-fitting curve:
#' plot(fits[[which.max(rmses)]])
#' 
#' # It is very straightforward to summarize the coefficients by a factor variable
#' # that was contained in the original data. In manyacidat, there is a factor variable
#' # 'treatment'.
#' # We first have to refit the curves, using the 'id' argument:
#' fits <- fitacis(manyacidat, "Curve", fitmethod="bilinear", id="treatment")
#' 
#' # And now use this to plot Vcmax by treatment.
#' boxplot(Vcmax ~ treatment, data=coef(fits), ylim=c(0,130))
#' 
#' # As of package version 1.4-2, you can also use the id variable for colouring curves,
#' # when plotting all fitted curves in one plot.
#' # Set colours to be used. Also note that the 'id' variable has to be a factor,
#' # colours will be set in order of the levels of the factor.
#' # Set palette of colours:
#' palette(rainbow(8))
#' 
#' # Use colours, add legend.
#' plot(fits, how="oneplot", colour_by_id = TRUE, id_legend=TRUE)
#'
#' }
#' 
#' @export
#' @importFrom utils setTxtProgressBar
#' @importFrom utils txtProgressBar
fitacis <- function(data, group, fitmethod=c("default","bilinear"),
                    progressbar=TRUE, quiet=FALSE, id=NULL, ...){
  
  fitmethod <- match.arg(fitmethod)
  
  if(!group %in% names(data))
    Stop("group variable must be in the dataframe.")
  
  if(quiet)progressbar <- FALSE
  
  data$group <- data[,group]
  tb <- table(data$group)
  
  if(any(tb == 0)){
    Stop("Some levels of your group variable have zero observations.",
         "\nUse droplevels() or fix data otherwise!")
  }
  
  d <- split(data, data[,"group"])  
  ng <- length(d)
  fits <- do_fit_bygroup(d, 1:ng, progressbar, fitmethod, id=id, ...)
  
  if(any(!fits$success)){
    if(!quiet){
      group_fail <- names(d)[!fits$success]
      message("The following groups could not be fit with fitmethod='default':")
      message(paste(group_fail,collapse="\n"))
    }
    
    # Refit bad curves using the 'bilinear' method
    if(fitmethod == "default"){
      if(!quiet)message("Fitting those curves with fitmethod='bilinear'.")
      refits <- do_fit_bygroup(d, which(!fits$success), progressbar=FALSE, fitmethod="bilinear", ...)
      
      fits$fits[!fits$success] <- refits$fits[!fits$success]
    }
  }
  
  l <- fits$fits
  class(l) <- "acifits"
  attributes(l)$groupname <- group
  
return(l)
}


do_fit_bygroup <- function(d, which, progressbar, fitmethod, ...){
  
  ng <- length(d)
  success <- vector("logical", length(which))
  
  if(progressbar){
    wp <- txtProgressBar(title = "Fitting A-Ci curves", 
                         label = "", min = 0, max = ng, initial = 0, 
                         width = 50, style=3)
  }
  
  fits <- list()
  for(i in which){
    f <- try(fitaci(d[[i]], quiet=TRUE, fitmethod=fitmethod, ...), silent=TRUE)
    success[i] <- !inherits(f, "try-error")
    
    fits[[i]] <- if(success[i]) f else NA
    if(progressbar)setTxtProgressBar(wp, i)
  }
  if(progressbar)close(wp)
  
  names(fits) <- names(d)[which]
  
  l <- list(fits=fits, success=success)
}


 


