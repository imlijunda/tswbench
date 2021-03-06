% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/realtime_sina.R
\name{sina_realtime_loader}
\alias{sina_realtime_loader}
\title{Generate a Sina realtime data loader function}
\usage{
sina_realtime_loader(
  db = get_srt_db(),
  today = idate_now(),
  api = TushareApi()
)
}
\arguments{
\item{db}{path to database file}

\item{today}{date of today}

\item{api}{a tsapi object}
}
\value{
a load function
}
\description{
Generate a Sina realtime data loader function
}
