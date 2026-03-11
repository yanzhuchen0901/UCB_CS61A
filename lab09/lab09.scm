(define (over-or-under num1 num2)(
  (cond ((> num1 num2) 1)
        ((< num1 num2) -1)
        (else 0)))

(define (make-adder num)
(lambda (a)(+ a num)))

(define (composed f g)
(define (com x)(f (g a))))

(define (repeat f n)(
  (if (= n 1))
  f
  (lambda (x)(f ((repeat f (- n 1))x)))))

(define (max a b)
  (if (> a b)
      a
      b))

(define (min a b)
  (if (> a b)
      b
      a))

(define (gcd a b)
  (if (= (remainder (max a b)(min a b))0)
  (min a b)
  (gcd (min a b)(remainder (max a b)(min a b)))))
