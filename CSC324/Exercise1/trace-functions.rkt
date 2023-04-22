#lang racket/base ; Version Sat Jan 15, 2022

; NOTE: Reading this code is NOT a required part of the course.

; Usage is best seen in practice in the course files for now.

; WARNING: Doesn't obey shadowing in nested functions (a teachable moment).

(provide show-expansion
         show-sub show-call
         (rename-out [traced:λ λ]
                     [traced:λ lambda]
                     [traced:define define]))

(require (prefix-in racket: (only-in racket/base λ define)))

(require (only-in racket/pretty pretty-print)
         (only-in racket/format ~a))

(define (value-rep v) (if (or (list? v) (symbol? v)) `',v v))
(define (unquoted-print v)
  (pretty-print v #:newline? #false (current-output-port) 1))

(define-syntax-rule (newlined statement ...)
  (begin (begin statement (newline)) ...))

(require syntax/parse/define (for-syntax racket/base
                                         (only-in racket/pretty pretty-print)))

(define-for-syntax (unquoted-print v)
  (pretty-print v #:newline? #false (current-output-port) 1))

(require racket/set)

(define-for-syntax showing-expansion? (make-parameter #false))
(define-syntax-parser show-expansion
  [(show-expansion show?:boolean)
   (showing-expansion? (syntax->datum (attribute show?)))
   #'(void)])

(begin-for-syntax
  (define-syntax-class id/λ #:attributes {name}
    [pattern (~or #:lambda #:λ _:id)
             #:with name (syntax-parse this-syntax [#:lambda #'#:λ] [f #'f])]))

(define show-subs (make-parameter (set)))
(define-syntax-parse-rule (show-sub :id/λ ...) (show-subs (set 'name ...)))
(define (showing-subs? f-id) (set-member? (show-subs) f-id))

(define show-calls (make-parameter (set)))
(define-syntax-parse-rule (show-call :id/λ ...) (show-calls (set 'name ...)))
(define (showing-calls? f-id) (set-member? (show-calls) f-id))

(define (any-showing? f-id) (or (showing-subs? f-id) (showing-calls? f-id)))

(define depth (make-parameter 0))
(define (display-depth)
  (display (make-string (sub1 (* 2 (depth))) #\—))
  (display " "))
(define-syntax-parse-rule
  (deepen-if c:expr d:expr ... (~optional (~seq #:else e:expr)))
  (if c (parameterize ([depth (add1 (depth))]) d ...) {~? e (void)}))

(define (display-call f-expr parameters arguments)
  (display-depth)
  (unquoted-print (list* f-expr (map value-rep arguments))) (newline))

(define (display-sub f-expr parameters body arguments)
  (for-each (λ (b-e) (unquoted-print (substitute b-e parameters arguments)))
            body)
  (newline))

(define (substitute expr parameters arguments)
  (define env (map cons parameters arguments))
  (let loop ([e expr])
    (cond [(list? e) (map loop e)]
          [(assoc e env) => cdr]
          [else e])))

(define (trace name f parameters body arguments do-body)
  ; Wrapping body in caller for multiple use also prevents multiple expansion.
  (define result (deepen-if (any-showing? name)
                            (display-call f parameters arguments)
                            (when (showing-subs? name)
                              (display-sub f parameters body arguments))
                            (do-body)
                            #:else (do-body)))
  (deepen-if (showing-calls? name)
             (display-depth) (print result) (newline))
  result)

(define-syntax-parser traced:λ
  [(~and f (_ (parameter:id ...) body:expr))
   (syntax/loc this-syntax (λ (parameter ...) (trace '#:λ
                                                     'f '(parameter ...) '(body)
                                                     `(,parameter ...)
                                                     (λ () body))))])

(define-syntax-parser traced:define
  #:literals {traced:define}
  [(_ (f:id parameter:id ...) (~and (traced:define . _) definition) ... e:expr)
   #:with body #'(definition ... e)
   (when (showing-expansion?)
     (unquoted-print (syntax->datum #'(define f (λ (parameter ...) . body))))
     (newline))
   (syntax/loc this-syntax (define (f parameter ...)
                             (trace 'f
                                    'f '(parameter ...) 'body
                                    `(,parameter ...)
                                    (λ () . body))))]
  [(_ var:id init:expr) (syntax/loc this-syntax (define var init))])
