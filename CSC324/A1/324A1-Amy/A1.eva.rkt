#lang racket ; CSC324 — 2023W — Assignment 1 — Eva Implementation

; Task: implement eva according to A1.eva-test.rkt.

(provide (contract-out
          (eva (any/c . -> . any/c))
          (subs (any/c any/c . -> . any/c))

          )
         ; Add any helper functions you tested in A1.eva-test.rkt.
         ; Whether you add contracts to them is optional.
          )

(define (subs closed val)
  (match closed
    ((list 'λ (list id) body)
     (if (list? body)
          (map (λ (x) (if (equal? x id) val x)) body)
          (if (equal? body id) val body)
     )))
)

(define (eva term)
   (match term
     ((list func arg)(eva (subs (eva func) (eva arg)))) ;function call
     (_ term) ;identifier & literal & λ term
   )
)
