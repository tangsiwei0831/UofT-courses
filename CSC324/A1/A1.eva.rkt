#lang racket ; CSC324 — 2023W — Assignment 1 — Eva Implementation

; Task: implement eva according to A1.eva-test.rkt.

(provide (contract-out (eva (any/c . -> . any/c)))
         ; Add any helper functions you tested in A1.eva-test.rkt.
         ; Whether you add contracts to them is optional.
         #;a-helper
         (contract-out (replace (any/c any/c . -> . any/c)))
         )

(define (replace func_term arg_term)
  (define (rep body check value)
    (match body
      [(list a b) (map (λ (x) (if (equal? x check) value x)) body)]
      [(app (λ (x) (and (not (list? x)) (equal? x check))) #t) value]
      [(app (λ (x) (and (not (list? x)) (not (equal? x check)))) #t) body]
      [_ body]))
  (rep (last func_term) (first (second func_term)) arg_term))

; Produce the value of a closed term from LCA.
(define (eva term)
  (match term
    ((list function argument) (eva (replace (eva function) (eva argument))))
    (term term)))