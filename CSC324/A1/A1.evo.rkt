#lang racket ; CSC324 — 2022W — Assignment 1 — Evo Implementation

; Task: implement evo according to A1.evo-test.rkt.

(require rackunit)

(provide
 (contract-out (evo (any/c . -> . (list/c any/c (hash/c symbol? list?)))))
 ; Add any helper functions you tested in A1.evo-test.rkt.
 ; Whether you add contracts to them is optional.
 #;a-helper)

; · Support: indexer and Void

(provide (contract-out (indexer (any/c . -> . (-> symbol?)))))

(define (indexer prefix)
  (define last-index -1)
  (λ ()
    (local-require (only-in racket/syntax format-symbol))
    (set! last-index (add1 last-index))
    (format-symbol "~a~a" prefix last-index)))

; There is no literal nor variable for the void value (although it has a printed
; representation when printed inside compound values), so we'll name it here and
; and also export it for testing.

(provide (contract-out (Void void?)))

(define Void (void))

; · evo

; Produce a two-element list with the value and the environment-closure table
; from evaluating an LCO term.
(define (evo term)

  ; A mutable table of environments and closures.
  (define environments-closures (make-hash))
  
  ; Iterators to produce indices for environments and closures.
  (define En (indexer 'E))
  (define λn (indexer 'λ))

  (define (var_eva var E)
    (if (equal? var (first (first (hash-ref environments-closures E))))
         (second (first (hash-ref environments-closures E)))
          (var_eva var (second (hash-ref environments-closures E)))
          )
    )

  (define (helper lambda-expr env-clsr En λn)
  (let ()
    (hash-set! env-clsr λn (list lambda-expr En))
    λn)
  )

  (define (rec-rest id env-clsr cur-env)
    (if (equal? cur-env 'E0)
        id
        (if (equal? id (first (first (hash-ref env-clsr cur-env))))
                (second (first (hash-ref env-clsr cur-env)))
                (rec-rest id env-clsr (second (hash-ref env-clsr cur-env))))
        )
  )


  ; Task: complete rec.
  (define (rec t E) (match t
                      [(list 'set! b c)
                       (set-box! (var_eva b E) (rec c E))
                       Void]
                      [(list 'λ parameter b)
                         (helper t environments-closures E (λn))]
                      [(list a b)
                         (a (rec b E))]
                      [a (if (box? (rec-rest a environments-closures E))
                                     (unbox (rec-rest a environments-closures E))
                                     (rec-rest a environments-closures E))]))
  
  (list (rec term (En))
        (make-immutable-hash (hash->list environments-closures))))


