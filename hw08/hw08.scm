(define (ascending? s) 
 (if (or (null? s) (null? (cdr s)))
    #t
    (if (> (car s) (car(cdr s)))
        #f
        (ascending? (cdr s))
)))

(define (my-filter pred s)
    (if (null? s)
        nil
    (if (pred (car s))
    (cons (car s) (my-filter pred (cdr s)))
    (my-filter pred (cdr s)))))

(define (interleave lst1 lst2)
(cond((null? lst1)lst2)
     ((null? lst2)lst1)
     (else(cons (car lst1) (cons (car lst2)(interleave (cdr lst1) (cdr lst2)))
))))

(define (no-repeats s)
(define (contains? x s)
  (if (null? s)
      #f
      (if (equal? x (car s))
          #t
          (contains? x (cdr s)))))
    (define (helper rest seen)
        (if (null? rest)
                nil
                (if (contains? (car rest) seen)
                        (helper (cdr rest) seen)
                        (cons (car rest)
                                    (helper (cdr rest)
                                                    (cons (car rest) seen))))))
    (helper s nil))