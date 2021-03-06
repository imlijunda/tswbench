% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/realtime_loop.R
\name{create_rt_loop}
\alias{create_rt_loop}
\title{Create a realtime data loop}
\usage{
create_rt_loop(
  query_func = sina_realtime_quote,
  ref_code = "sz000001",
  code_col = "sina_code",
  time_col = "Time",
  db = get_rt_db(),
  tbl_name = "rtdt",
  idx_unique = paste0(tbl_name, "_idx_unique"),
  idx_dttm = paste0(tbl_name, "_idx_dttm"),
  idx_recv = paste0(tbl_name, "_idx_recv"),
  sleep_timer = rt_sleep_timer,
  exit_timer = rt_exit_timer,
  min_loop_time = 1,
  report_window = 30L,
  api = TushareApi()
)
}
\arguments{
\item{query_func}{a query function to fetch realtime data}

\item{ref_code}{a reference code to query and determine data structure returned by query_func}

\item{code_col}{column name to code}

\item{time_col}{column name to time}

\item{db}{path to database}

\item{tbl_name}{table name to store data}

\item{idx_unique}{index name to identify unique entries}

\item{idx_dttm}{index on datetime}

\item{idx_recv}{index on time received}

\item{sleep_timer}{a sleep timer function}

\item{exit_timer}{an exit timer function}

\item{min_loop_time}{minimum loop time}

\item{report_window}{report window size}

\item{api}{a tsapi object}
}
\value{
a function to run the loop
}
\description{
Create a realtime data loop
}
