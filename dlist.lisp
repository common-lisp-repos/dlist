(in-package #:dlist)

(defclass dlist (#+generic-sequences sequence standard-object)
  ((first :initarg :first :accessor %dlist-first)
   (last :initarg :last :accessor %dlist-last))
  (:documentation   "A class that represents a doubly-linked list"))

(defun dlist-first (dlist)
  "Gets the first `dcons' in a `dlist'"
  (cond
    ((not dlist) nil)
    ((typep dlist 'dcons) dlist)
    (t (%dlist-first dlist))))

(defun dlist-last (dlist)
  "Gets the last `dcons' in a `dlist'"
  (cond
    ((not dlist) nil)
    ((typep dlist 'dcons) (loop for i = dlist then (next dlist) while (next i) finally (return i)))
    (t (%dlist-last dlist))))

(defun (setf dlist-first) (val place)
  (setf (%dlist-first place) val))

(defun (setf dlist-last) (val place)
  (setf (%dlist-last place) val))

(defun dlist-cons-on (object dlist)
  "Returns a dlist whose elements are `object' and the elements of `dlist'. `dlist' is destructively mosified. This is intended to have the same use as @code{(cons object list)} for regular lists."
  (let ((new-cons (dcons nil object dlist)))
    (setf (prev dlist) new-cons)
    new-cons))

(defun dcons-append (object dcons)
  "Creates a dcons whose `data' is `object' and appends it to `dcons', returning `dcons' with a pointer to the new dcons in `dcons''s next."
  (let ((new-dcons (dcons dcons object nil)))
    (setf (next dcons) new-dcons)
    dcons))

(defun dlist (&rest elements)
  "Returns a doubly-linked list (dlist) with the elements in `elements'"
  (when elements
    (if (= (length elements) 1)
	(let* ((dcons (dcons nil (car elements) nil)) (dlist (make-instance 'dlist :first dcons :last dcons)))
	  dlist)
	(let ((dlist (make-instance 'dlist)) (current-dcons nil))
	  (setf (dlist-first dlist) (dcons nil (first elements) nil))
	  (setf current-dcons (dlist-first dlist))
	  (loop for i on (rest elements) do
	       (setf current-dcons (next (dcons-append (car i) current-dcons)))
	       (or (cdr i) (setf (dlist-last dlist) current-dcons)))
	  dlist))))

(defun dlist= (dlist &rest more-dlists)
  "Tests dlists for equality by element, recursively descending into sub-dlists."
  (unless more-dlists (return-from dlist= t))
  (if (cdr more-dlists) ;;Test for a list of length > 1
      (every #'(lambda (x) (dlist= dlist x)) more-dlists)
      (loop for i = (dlist-first dlist) then (next i)
	   for j = (dlist-first (first more-dlists)) then (next j)
	   until (and (eql i nil) (eql j nil))
	   always
	   (if (and (typep (data i) 'dlist) (typep (data j) 'dlist))
	       (dlist= (data i) (data j))
	       (equal (data i) (data j))))))

(defun dlistp (object)
  "Tests if `object' is a dlist."
  (or (typep object 'dlist) (not object)))

(defun dlist->list (dlist)
  "Converts a dlist to a list"
  (loop for i = (dlist-first dlist) then (next i) while i collect (data i)))

(defun nthdcons (n dlist)
  "Returns the nth dcons in `dlist' (zero-based). If n is >= the length of the list, returns NIL."
  (let ((val (dlist-first dlist)))
    (dotimes (i n val)
      (setf val (next val)))))

(defun dlist-nth (n dlist)
  "Returns the nth element of `dlist', as the primary value. If n is >= the length of the list, NIL will be returned. The secondary value will be T if the value was actually found in the list, and NIL otherwise."
  (let ((ret (nthdcons n dlist)))
    (values (data ret) (not (not ret)))))

(defun (setf dlist-nth) (val n dlist)
  "Sets the data of the nth dcons in `dlist' to `val'"
  (setf (data (nthdcons n dlist)) val))

(defmethod print-object ((object dlist) stream)
  (print-unreadable-object (object stream :type t)
    (print (dlist->list object) stream)))

(defmethod describe-object ((dlist dlist) stream)
  (let ((*print-circle* t))
    (format stream "~&~S is a doubly-linked list (dlist) which has the elements ~S.~% Its first dcons is ~S, and its last dcons is ~S." dlist (dlist->list dlist) (dlist-first dlist) (dlist-last dlist))))
