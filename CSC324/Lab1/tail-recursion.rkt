#lang racket

; sum using standard recursion and tail-recursion

(require "trace-functions.rkt")
(show-sub recsum tail-recsum) ; Show calls of (just) scroll as algebraic substitution.
(show-call recsum tail-recsum) ; Show calls and returns of (just) these.

(define (recsum x)
  (if (zero? x)
       0
       (+ x (recsum (- x 1)))))

(recsum 5)

(define (tail-recsum x sum)
  (if (zero? x)
       sum
       (tail-recsum (- x 1) (+ sum x))))

(tail-recsum 5 0)