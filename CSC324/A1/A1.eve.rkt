#lang racket ; CSC324 — 2023W — Assignment 1 — Eve Implementation

; Task: implement eve according to A1.eve-test.rkt.

(provide
 (contract-out (eve (any/c . -> . (list/c any/c (hash/c symbol? list?)))))
 ; Add any helper functions you tested in A1.eva-test.rkt.
 ; Whether you add contracts to them is optional.
 #;a-helper)

; · Support: indexer

; A constructor for a zero-arity function that when called successively
; produces symbols of the form prefix0 prefix1 prefix2 etc.

(provide (contract-out (indexer (any/c . -> . (-> symbol?)))))

(define (indexer prefix)
  (define last-index -1)
  (λ ()
    (local-require (only-in racket/syntax format-symbol))
    (set! last-index (add1 last-index))
    (format-symbol "~a~a" prefix last-index)))

; · eve

; Produce a two-element list with the value and the environment-closure table
; from evaluating an LCE term.
(define (eve term)

  ; A mutable table of environments and closures.
  ; Task: Look up hash-ref and hash-set! in the racket documentation.
  (define environments-closures (make-hash))
  
  ; Iterators to produce indices for environments and closures.
  (define En (indexer 'E))
  (define λn (indexer 'λ))

  (define (rec-var var E)
    (cond [(equal? var (first (first (hash-ref environments-closures E)))) (second (second (hash-ref environments-closures E)))]
         [else (rec-var var (second (hash-ref environments-closures E)))]))



  (define (closure lambda-expr environments-closures En λn)
    (hash-set! environments-closures λn (list lambda-expr En))
    λn 
    )

  (define (com num cbine nxtenv newenv)
     (hash-set! environments-closures newenv (list (list (first (second cbine)) num) nxtenv))
     (list (last cbine) newenv)
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
                      ;lambda
                      ((list 'λ parameter body)(closure t environments-closures E (λn)))
                      ;function
                      ((list a b)
                       (let* ([func (rec a E)]
                             [arg (rec b E)]
                             [cbine (first (hash-ref environments-closures func))]
                             [nxtenv (second (hash-ref environments-closures func))]
                             [combine-rst (com arg cbine nxtenv (En))])
                         (rec (first combine-rst) (second combine-rst)))
                       )
                      ; rest
                      (a (rec-rest a environments-closures E))
                      ))
  
  (list (rec term (En))
        (make-immutable-hash (hash->list environments-closures))))
