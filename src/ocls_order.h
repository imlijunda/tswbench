#pragma once

#include "ocls_common.h"
#include "sdeque.h"
#include "psquare.h"
#include "kll.h"

// ===== ocls_moving_sort =====
class ocls_moving_sort {

  int n, w;
  deque buf;
  sdeque<double> sorted;

public:
  ocls_moving_sort(int window);

  double get_index(int idx);
  Rcpp::NumericVector to_vector();
  void update_one(double x);
  void update(Rcpp::NumericVector x);
  Rcpp::NumericVector value();
};

// ===== ocls_moving_median =====
class ocls_moving_median {

  int n, w, idx1, idx2;
  deque buf;
  sdeque<double> sorted;

public:
  ocls_moving_median(int window);

  double update_one(double x);
  Rcpp::NumericVector update(Rcpp::NumericVector x);
  double value();
};

// ===== ocls_moving_quantile =====
class ocls_moving_quantile {

  int n, w, nidx;
  deque buf;
  sdeque<double> sorted;
  Rcpp::IntegerVector qidx;

public:
  ocls_moving_quantile(int window, Rcpp::IntegerVector idx);

  Rcpp::NumericVector update_one(double x);
  Rcpp::NumericMatrix update(Rcpp::NumericVector x);
  Rcpp::NumericVector value();
};

// ===== ocls_cumulative_psquare =====
class ocls_cumulative_psquare {

  int nq;
  std::vector<psquare> psq;

public:
  ocls_cumulative_psquare(Rcpp::NumericVector q);

  Rcpp::NumericVector update_one(double x);
  Rcpp::NumericMatrix update(Rcpp::NumericVector x);
  Rcpp::NumericVector value();
};

// ===== ocls_cumulative_quantile =====
class ocls_cumulative_quantile {

  KLL<double> kll;

public:
  ocls_cumulative_quantile(int k, double c, bool lazy);

  Rcpp::NumericMatrix update_one(double x);
  Rcpp::NumericMatrix update(Rcpp::NumericVector x);
  Rcpp::NumericMatrix value();
  void insert(Rcpp::NumericVector x);
  Rcpp::NumericVector quantile(Rcpp::NumericVector probs);
};
