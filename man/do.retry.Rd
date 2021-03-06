% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tushare_api.R
\name{do.retry}
\alias{do.retry}
\title{Simple do.call retry wrapper}
\usage{
do.retry(
  what,
  args,
  quote = FALSE,
  envir = parent.frame(),
  attempt = 3,
  sleep = 0,
  handler = warning_handler
)
}
\arguments{
\item{what}{passed to do.call}

\item{args}{passed to do.call}

\item{quote}{passed to do.call}

\item{envir}{passed to do.call}

\item{attempt}{max number of attempts}

\item{sleep}{sleep time between attempts}

\item{handler}{error handling function}
}
\value{
The returned value from function call
}
\description{
Simple do.call retry wrapper
}
