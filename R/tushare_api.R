#' Set/Get Tushare Pro API token
#'
#' @param token a character vector
#' @param save save set token to token_file
#' @param token_file path to token_file
#'
#' @return token itself, invisibly.
#' @export
SetToken <- function(token, save = FALSE, token_file = "~/tk.csv") {

  tus.globals$api_token <- as.character(token)
  if (save)
  {
    csv <- list(token = token)
    data.table::fwrite(data.table::setDT(csv), token_file)
  }

  invisible(tus.globals$api_token)
}

#' @rdname SetToken
#' @export
GetToken <- function(token_file = "~/tk.csv") {

  if (is.null(tus.globals$api_token)) {
    if (file.exists(token_file))
    {
      token <- data.table::fread(token_file)
      tus.globals$api_token <- token$token[1]
    }
    else
    {
      tus.globals$api_token <- ""
    }
  }
  tus.globals$api_token
}

warning_handler <- function(e) warning(e, call. = FALSE, immediate. = TRUE)

#' Simple do.call retry wrapper
#'
#' @param what passed to do.call
#' @param args passed to do.call
#' @param quote passed to do.call
#' @param envir passed to do.call
#' @param attempt max number of attempts
#' @param sleep sleep time between attempts
#' @param handler error handling function
#'
#' @return The returned value from function call
do.retry <- function(what, args, quote = FALSE, envir = parent.frame(),
                     attempt = 3, sleep = 0, handler = warning_handler) {

  flag <- FALSE

  err_func <- function(e) {
    flag <<- FALSE
    handler(e)
    Sys.sleep(sleep)
  }

  for (i in seq_len(attempt)) {
    flag <- TRUE
    ans <- tryCatch({
      do.call(what, args, quote, envir)
    }, error = err_func)
    if (flag) {
      return(ans)
    }
  }

  msg <- do.call(paste0, args = as.list(
    as.character(deparse(substitute(what, envir)))
  ))
  stop(sprintf("Calling %s failed after %d attempts.", msg, attempt), call. = FALSE)
}

#' Make raw request to Tushare Pro API
#'
#' @param api_name name of API function, please refer to online document for more information.
#' @param ... passed to API function.
#' @param fields data fields to request
#' @param token API token.
#' @param timeout timeout in seconds for httr request.
#'
#' @return data.frame/data.table
TusRequest <- function(api_name, ..., fields = c(""), token = GetToken(), timeout = 5.0) {

  api_url <- "http://api.waditu.com"

  req_body <- list(
    token    = as.character(token),
    api_name = api_name,
    params   = list(...),
    fields   = fields
  )

  req <- httr::POST(url = api_url,
                    config = httr::timeout(timeout),
                    body = req_body,
                    encode = "json")
  res <- httr::content(req,
                       as = "parsed",
                       type = "application/json",
                       encoding = "UTF-8")

  if (is.null(res$data)) {
    stop(res$msg, call. = FALSE)
  }

  suppressWarnings({
    if (length(res$data$items)) {
      dt <- tryCatch({
        data.table::rbindlist(res$data$items)
      }, error = function(e) {
        #error happens when null ROW is passed by fromJSON()
        null_row <- sapply(res$data$items, is.null)
        na_row <- sapply(res$data$items, is.na)
        ignore_row <- null_row | na_row
        data.table::rbindlist(res$data$items[!ignore_row])
      })
    } else {
      #create an empty data.table
      dt <- do.call(data.table::data.table,
                    rep_len(x = list(logical()), length.out = length(res$data$fields)))
    }
  })
  data.table::setnames(dt, unlist(res$data$fields))

  dt
}

#' Get a Tushare API object.
#'
#' @param api_token API token.
#' @param time_mode data type for time objects
#' @param date_mode data type for date objects
#' @param logi_mode data type for logical objects
#' @param tz Default timezone of POSIXct data
#'
#' @return a tsapi object.
#' @export
#'
TushareApi <- function(api_token = GetToken(),
                       time_mode = c("POSIXct", "ITime", "char"),
                       date_mode = c("Date", "POSIXct", "IDate", "char"),
                       logi_mode = c("logical", "char"),
                       tz = "Asia/Shanghai") {

  time_mode <- match.arg(time_mode)
  date_mode <- match.arg(date_mode)
  logi_mode <- match.arg(logi_mode)

  return(
    structure(api_token,
      time_mode = time_mode,
      date_mode = date_mode,
      logi_mode = logi_mode,
      tz        = tz,
      class     = "tsapi")
  )
}

#' Print Values
#'
#' @param x A tsapi object
#' @param ... not used
#'
#' @return x, invisibly
#' @export
#'
'print.tsapi' <- function(x, ...) {

  val <- sprintf("Tushare API object.\n  Time mode: %s\n  Date mode: %s\n  Logi mode: %s\n  Default timezone: %s",
                 attr(x, "time_mode"),
                 attr(x, "date_mode"),
                 attr(x, "logi_mode"),
                 attr(x, "tz"))
  cat(val)

  invisible(x)
}

arg_logi <- c("is_open", "is_new", "is_audit", "is_release", "is_buyback",
              "is_ct", "update_flag")

#' Request data from Tushare API
#'
#' @param x A tsapi object
#' @param func Tushare API function to call
#'
#' @return a data.table
#' @export
#'
'$.tsapi' <- function(x, func) {

  force(x)
  force(func)
  f <- function(..., timeout = 5.0, attempt = 3L, retry_wait = 0.5) {

    arg <- list(...)

    #fix date/time/logical arguments
    argn <- names(arg)

    #datetime
    idx <- stringr::str_detect(argn, "date$|time$|^period$")
    if (any(idx)) {
      arg[idx] <- lapply(arg[idx], datetime_to_char, tz = get_tz(x))
    }
    #logical
    for (i in seq_along(arg)) {
      if (is.logical(arg[[i]])) {
        arg[[i]] <- ifelse(arg[[i]], "1", "0")
      }
    }

    #extra arguments passed to TusRequest()
    arg$api_name <- func
    arg$token    <- x
    arg$timeout  <- timeout

    dt <- do.retry(TusRequest, arg, attempt = attempt, sleep = retry_wait)

    #parse dt
    if (nrow(dt)) {
      parse_date     <- date_parser(x)
      parse_datetime <- datetime_parser(x)
      parse_logical  <- logical_parser(x)

      cols <- colnames(dt)
      #parse date columns
      col_date <- which(stringr::str_detect(cols, "date$|^period$"))
      if (length(col_date)) {
        dt[, (col_date) := lapply(.SD, parse_date), .SDcol = col_date]
      }
      #parse datetime columns
      col_time <- which(stringr::str_detect(cols, "time$"))
      if (length(col_time)) {
        dt[, (col_time) := lapply(.SD, parse_datetime), .SDcol = col_time]
      }
      #parse logical columns
      col_logi <- which(cols %in% arg_logi)
      if (length(col_logi)) {
        dt[, (col_logi) := lapply(.SD, parse_logical), .SDcol = col_logi]
      }

      #set keys
      keys <- NULL
      dttm_idx <- c(col_time, col_date)
      if ("ts_code" %in% cols) {
        keys <- "ts_code"
      }
      if (length(dttm_idx)) {
        keys <- c(keys, cols[dttm_idx[1]])
      }
      if (length(keys)) {
        data.table::setkeyv(dt, keys)
      }

      #fix update_flag issue for fundamental data
      if (("update_flag" %in% cols) && ("ts_code" %in% cols) && ("end_date" %in% cols)) {
        data.table::setkeyv(dt, c("ts_code", "end_date", "update_flag"))
        dt <- dt[, lapply(.SD, last), by = c("ts_code", "end_date")]
      }
    }

    dt
  }

  f
}
