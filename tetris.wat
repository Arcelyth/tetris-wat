(module
  (import "canvas" "getCtx" (func $js_getCtx (result externref)))
  (import "draw" "setFillColor" (func $js_setFillColor (param externref i32 i32 i32)))
  (import "draw" "fillRect" (func $js_fillRect (param externref i32 i32 i32 i32)))
  (import "draw" "updateUI" (func $js_updateUI (param i32 i32)))
  (import "tool" "random" (func $js_random (result i32)))
  (import "tool" "alert" (func $js_alert (param i32)))

  (type $RowType (array (mut i32)))
  (type $MatrixType (array (mut (ref null $RowType)))) 
  (type $ShapesType (array (ref $MatrixType)))

  (type $Pos (struct (field $x (mut i32)) (field $y (mut i32))))

  (type $Cur 
    (struct
      (field $pos (ref $Pos)) 
      (field $matrix (mut (ref null $MatrixType)))
      (field $id (mut i32))
    )
  )

  (global $SHAPES (ref $ShapesType)
    (array.new_fixed $ShapesType 8
      ;; empty
      (array.new_fixed $MatrixType 0)
      ;; I
      (array.new_fixed $MatrixType 4
        (array.new_fixed $RowType 4 (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0))
        (array.new_fixed $RowType 4 (i32.const 1) (i32.const 1) (i32.const 1) (i32.const 1))
        (array.new_fixed $RowType 4 (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0))
        (array.new_fixed $RowType 4 (i32.const 0) (i32.const 0) (i32.const 0) (i32.const 0))
      )
      ;; J
      (array.new_fixed $MatrixType 3
        (array.new_fixed $RowType 3 (i32.const 2) (i32.const 0) (i32.const 0))
        (array.new_fixed $RowType 3 (i32.const 2) (i32.const 2) (i32.const 2))
        (array.new_fixed $RowType 3 (i32.const 0) (i32.const 0) (i32.const 0))
      )
      ;; L
      (array.new_fixed $MatrixType 3
        (array.new_fixed $RowType 3 (i32.const 0) (i32.const 0) (i32.const 3))
        (array.new_fixed $RowType 3 (i32.const 3) (i32.const 3) (i32.const 3))
        (array.new_fixed $RowType 3 (i32.const 0) (i32.const 0) (i32.const 0))
      )

      ;; O
      (array.new_fixed $MatrixType 2
        (array.new_fixed $RowType 2 (i32.const 4) (i32.const 4))
        (array.new_fixed $RowType 2 (i32.const 4) (i32.const 4))
      )

      ;; S
      (array.new_fixed $MatrixType 3
        (array.new_fixed $RowType 3 (i32.const 0) (i32.const 5) (i32.const 5))
        (array.new_fixed $RowType 3 (i32.const 5) (i32.const 5) (i32.const 0))
        (array.new_fixed $RowType 3 (i32.const 0) (i32.const 0) (i32.const 0))
      )

      ;; T
      (array.new_fixed $MatrixType 3
        (array.new_fixed $RowType 3 (i32.const 0) (i32.const 6) (i32.const 0))
        (array.new_fixed $RowType 3 (i32.const 6) (i32.const 6) (i32.const 6))
        (array.new_fixed $RowType 3 (i32.const 0) (i32.const 0) (i32.const 0))
      )

      ;; Z
      (array.new_fixed $MatrixType 3
        (array.new_fixed $RowType 3 (i32.const 7) (i32.const 7) (i32.const 0))
        (array.new_fixed $RowType 3 (i32.const 0) (i32.const 7) (i32.const 7))
        (array.new_fixed $RowType 3 (i32.const 0) (i32.const 0) (i32.const 0))
      )
    )
  )

  (global $map (mut (ref null $MatrixType)) (ref.null $MatrixType))

  (func $createMat (param $w i32) (param $h i32) (result (ref $MatrixType))
    (local $mat (ref $MatrixType))
    (local $y i32)

    (array.new $MatrixType (ref.null $RowType) (local.get $h))
    local.set $mat

    (local.set $y (i32.const 0))
    (block $brk
      (loop $lp
        (i32.ge_s (local.get $y) (local.get $h))
        br_if $brk

        (array.set $MatrixType (local.get $mat) (local.get $y) (array.new $RowType (i32.const 0) (local.get $w)))

        (i32.add (local.get $y) (i32.const 1))
        local.set $y
        br $lp
      )
    )
    local.get $mat
  )

  (global $COLS i32 (i32.const 10))
  (global $ROWS i32 (i32.const 20))
  (global $BLOCK_SIZE i32 (i32.const 30))

  (global $cur (ref $Cur)
    (struct.new $Cur
      (struct.new $Pos (i32.const 0) (i32.const 0))
      (array.new_fixed $MatrixType 0)
      (i32.const 0)
    )
  )

  (global $lastTime (mut f64) (f64.const 0.0))
  (global $dropInterval (mut f64) (f64.const 200.0))
  (global $dropCounter (mut f64) (f64.const 0.0))
  (global $scores (mut i32) (i32.const 0))
  (global $lines (mut i32) (i32.const 0))
  (global $gameOver (mut i32) (i32.const 0))

  (func $collide (result i32)
    (local $mat (ref $MatrixType))
    (local $pos (ref $Pos))
    (local $len_x i32) (local $len_y i32)
    (local $x i32) (local $y i32)
    (local $tx i32) (local $ty i32)
    (local $row (ref $RowType))
    
    global.get $cur 
    (ref.as_non_null (struct.get $Cur $matrix))
    local.set $mat 

    global.get $cur 
    (local.set $pos (struct.get $Cur $pos))

    (array.len (local.get $mat))
    local.set $len_y
    (local.set $y (i32.const 0))
    (block $out 
      (loop $out_lp
        (i32.ge_s (local.get $y) (local.get $len_y))
        br_if $out

        (ref.as_non_null (array.get $MatrixType (local.get $mat) (local.get $y)))
        local.set $row
        (array.len (local.get $row))
        local.set $len_x

        (local.set $x (i32.const 0))
        (block $in
          (loop $in_lp
            (i32.ge_s (local.get $x) (local.get $len_x))
            br_if $in

            (array.get $RowType (local.get $row) (local.get $x))
            if 
              local.get $pos
              struct.get $Pos $x
              local.get $x
              i32.add 
              local.set $tx

              local.get $pos
              struct.get $Pos $y
              local.get $y
              i32.add 
              local.set $ty

              (i32.lt_s (local.get $tx) (i32.const 0))
              (i32.ge_s (local.get $tx) (global.get $COLS))
              i32.or
              (i32.ge_s (local.get $ty) (global.get $ROWS))
              i32.or
              if 
                ;; true
                (return (i32.const 1))
              end
              (i32.ge_s (local.get $ty) (i32.const 0))
              if 
                (ref.as_non_null (global.get $map))
                local.get $ty
                array.get $MatrixType
                local.get $tx
                array.get $RowType
                if 
                  (return (i32.const 1))
                end
              end
            end
            (i32.add (local.get $x) (i32.const 1))
            local.set $x
            br $in_lp
          )
        )
        (i32.add (local.get $y) (i32.const 1))
        local.set $y
        br $out_lp
      )
    )
    ;; false
    i32.const 0
  )

  (func $newCur
    (local $id i32)
    (local $mat (ref $MatrixType))

    (i32.add (i32.const 1) (call $js_random))
    local.set $id

    (global.get $cur) (local.get $id)
    struct.set $Cur $id
    (array.get $ShapesType (global.get $SHAPES) (local.get $id))
    local.set $mat

    (global.get $cur) (local.get $mat)
    struct.set $Cur $matrix

    (global.get $cur) (struct.get $Cur $pos)
    (struct.set $Pos $y (i32.const 0))
    (global.get $cur)
    struct.get $Cur $pos
    (i32.div_s (global.get $COLS) (i32.const 2))
    (array.len (array.get $MatrixType (local.get $mat) (i32.const 0)))
    i32.const 2
    i32.div_s
    i32.sub
    struct.set $Pos $x
    call $collide
    if 
      (global.set $gameOver (i32.const 1))
      (call $js_alert (global.get $scores))
      call $reset
    end
  )

  (func $move (export "move") (param $dir i32)
    (local $pos_obj (ref $Pos))
    (local.set $pos_obj (struct.get $Cur $pos (global.get $cur)))

    local.get $pos_obj
    (i32.add (struct.get $Pos $x (local.get $pos_obj)) (local.get $dir))
    struct.set $Pos $x

    call $collide
    if 
      local.get $pos_obj
      (i32.sub (struct.get $Pos $x (local.get $pos_obj)) (local.get $dir))
      struct.set $Pos $x
    end
  )

  (func $fix
    (local $mat (ref $MatrixType))
    (local $pos (ref $Pos))
    (local $len_x i32) (local $len_y i32)
    (local $x i32) (local $y i32)
    (local $row (ref $RowType))
    (local $val i32)

    (ref.as_non_null (struct.get $Cur $matrix (global.get $cur)))
    local.set $mat
    (struct.get $Cur $pos (global.get $cur))
    local.set $pos

    (array.len (local.get $mat))
    local.set $len_y
    (local.set $y (i32.const 0))
    (block $out
      (loop $out_lp
        (i32.ge_s (local.get $y) (local.get $len_y))
        br_if $out
       
        (ref.as_non_null (array.get $MatrixType (local.get $y (local.get $mat))))
        local.set $row

        (array.len (local.get $row))
        local.set $len_x

        (local.set $x (i32.const 0))
        (block $in
          (loop $in_lp
            (i32.ge_s (local.get $x) (local.get $len_x))
            br_if $in

            (array.get $RowType (local.get $x (local.get $row)))
            local.set $val

            (i32.ne (local.get $val) (i32.const 0))
            if 
              (ref.as_non_null (global.get $map))
              ;; pos.y +y
              local.get $pos
              struct.get $Pos $y
              local.get $y
              i32.add 

              (ref.as_non_null (array.get $MatrixType))
              local.get $pos
              struct.get $Pos $x
              local.get $x
              i32.add 

              (array.set $RowType (local.get $val))
            end

            (i32.add (local.get $x) (i32.const 1))
            local.set $x
            br $in_lp
          )
        )

        (i32.add (local.get $y) (i32.const 1))
        local.set $y
        br $out_lp
      )
    )
  )

  (func $sweepLine
    (local $row_count i32)
    (local $is_full i32)
    (local $map_obj (ref $MatrixType))
    (local $x i32) (local $y i32)
    (local $row (ref $RowType))
    (local $i i32)

    (local.set $map_obj (ref.as_non_null (global.get $map)))
    (local.set $row_count (i32.const 0))

    (i32.sub (global.get $ROWS) (i32.const 1))
    local.set $y
    (block $y_brk
      (loop $y_lp
        (i32.lt_s (local.get $y) (i32.const 0))
        br_if $y_brk

        (local.set $is_full (i32.const 1))

        (local.set $x (i32.const 0))
        (local.set $row (ref.as_non_null (array.get $MatrixType (local.get $map_obj) (local.get $y))))
        (block $x_brk
          (loop $x_lp
            (i32.ge_s (local.get $x) (global.get $COLS))
            br_if $x_brk

            (i32.eq (array.get $RowType (local.get $x (local.get $row))) (i32.const 0))
            if 
              (local.set $is_full (i32.const 0))
              br $x_brk 
            end

            (i32.add (local.get $x) (i32.const 1)) 
            local.set $x
            br $x_lp
          )
        )
        local.get $is_full
        if 
          local.get $y  
          local.set $i
          (block $shf
            (loop $shf_lp
              (i32.le_s (local.get $i) (i32.const 0))
              br_if $shf

              local.get $map_obj
              local.get $i
                local.get $map_obj
                local.get $i
                i32.const 1
                i32.sub
                array.get $MatrixType
              array.set $MatrixType

              (i32.sub (local.get $i) (i32.const 1))
              local.set $i
              br $shf_lp
            )
          )
          local.get $map_obj
          i32.const 0
          (array.new $RowType (i32.const 0) (global.get $COLS))
          array.set $MatrixType

          (local.set $row_count (i32.add (local.get $row_count) (i32.const 1)))
        else 
          (local.set $y (i32.sub (local.get $y) (i32.const 1)))
        end
        br $y_lp
      )
    )
    (i32.gt_s (local.get $row_count) (i32.const 0))
    if 
      (i32.add (global.get $scores) (i32.const 100))
      global.set $scores
      (i32.add (local.get $row_count) (global.get $lines))
      global.set $lines
      (call $js_updateUI (global.get $scores) (global.get $lines))
    end
  )

  (func $rotate (param $mat (ref $MatrixType)) (result (ref $MatrixType))
    (local $n i32)
    (local $r (ref $MatrixType))
    (local $x i32) (local $y i32)

    (local.set $n (array.len (local.get $mat)))
    (call $createMat (local.get $n) (local.get $n))
    local.set $r
    (local.set $y (i32.const 0))
    (block $out
      (loop $out_lp
        (i32.ge_s (local.get $y) (local.get $n))
        br_if $out

        (local.set $x (i32.const 0))
        (block $in
          (loop $in_lp
            ;; r[x][n - 1 - y] = mat[y][x]
            (i32.ge_s (local.get $x) (local.get $n))
            br_if $in

            (ref.as_non_null (array.get $MatrixType (local.get $x (local.get $r))))
            (i32.sub (i32.sub (local.get $n) (i32.const 1)) (local.get $y))

            (ref.as_non_null (array.get $MatrixType (local.get $y (local.get $mat))))
            local.get $x
            array.get $RowType
            array.set $RowType

            (i32.add (i32.const 1) (local.get $x))
            local.set $x
            br $in_lp
          )
        )

        (i32.add (i32.const 1) (local.get $y))
        local.set $y
        br $out_lp
      )
    )
    local.get $r
  )

  (func $curRotate (export "curRotate") 
    (local $p i32)
    (local $offset i32)
    (local $max_len i32)
    (local $pos_obj (ref $Pos))
    (local $old_mat (ref $MatrixType))

    (local.set $pos_obj (struct.get $Cur $pos (global.get $cur)))

    (struct.get $Pos $x (local.get $pos_obj))
    local.set $p

    (local.set $offset(i32.const 1))
    (ref.as_non_null (struct.get $Cur $matrix (global.get $cur)))
    local.set $old_mat

    global.get $cur
    (ref.as_non_null (struct.get $Cur $matrix (global.get $cur)))
    call $rotate
    struct.set $Cur $matrix

    (array.len (ref.as_non_null (array.get $MatrixType (i32.const 0 (local.get $old_mat)))))
    local.set $max_len
    (loop $co
      call $collide
      if 
        local.get $pos_obj
        (i32.add (struct.get $Pos $x (local.get $pos_obj)) (local.get $offset))
        struct.set $Pos $x

        ;; offset = -(offset + (offset > 0 ? 1 : -1))
        i32.const 0
          local.get $offset
            (i32.gt_s (local.get $offset) (i32.const 0))
            if (result i32)
              i32.const 1
            else 
              i32.const -1
            end
          i32.add
        i32.sub
        local.set $offset

        (i32.lt_s (local.get $offset) (i32.const 0))
        if (result i32) 
          i32.const 0
          local.get $offset
          i32.sub
        else
          local.get $offset 
        end
        local.get $max_len
        i32.gt_s

        if 
          (struct.set $Cur $matrix (local.get $old_mat (global.get $cur)))
          (struct.set $Pos $x (local.get $p (local.get $pos_obj)))
          return
        end
        br $co
      end
    )

  )

  (func $drop (export "drop")
    (local $pos_obj (ref $Pos))
    (local $orig_y i32)
    global.get $cur
    struct.get $Cur $pos
    local.set $pos_obj

    ;; cur.pos.y++
    local.get $pos_obj
    (local.set $orig_y (struct.get $Pos $y))
    local.get $pos_obj
    (i32.add (local.get $orig_y) (i32.const 1))
    struct.set $Pos $y
    call $collide
    if 
      local.get $pos_obj
      (i32.sub (struct.get $Pos $y (local.get $pos_obj)) (i32.const 1))
      struct.set $Pos $y
      call $fix
      call $sweepLine
      call $newCur
    end
    f64.const 0.0 global.set $dropCounter
  )

  (func $drawMat (param $mat (ref $MatrixType)) (param $offset (ref $Pos))
    (local $ctx externref)
    (local $offset_x i32) 
    (local $offset_y i32) 
    (local $x i32) 
    (local $y i32) 
    (local $pixel_x i32) 
    (local $pixel_y i32) 
    (local $len_x i32) 
    (local $len_y i32) 
    (local $cur_row (ref $RowType))
    (local $val i32)

    (local.set $ctx (call $js_getCtx))
    local.get $offset
    struct.get $Pos $x
    local.set $offset_x

    local.get $offset
    struct.get $Pos $y
    local.set $offset_y

    (array.len (local.get $mat))
    local.set $len_y

    (local.set $y (i32.const 0))
    (block $out_break
      (loop $out_loop
        (i32.ge_s (local.get $y) (local.get $len_y))
        br_if $out_break

        local.get $mat 
        local.get $y
        (ref.as_non_null (array.get $MatrixType))
        local.set $cur_row 
        
        (array.len (local.get $cur_row))
        local.set $len_x

        (local.set $x (i32.const 0))
        (block $in_break
          (loop $in_loop 
            (i32.ge_s (local.get $x) (local.get $len_x))
            br_if $in_break

            local.get $cur_row
            local.get $x

            array.get $RowType
            local.set $val
            
            (i32.ne (local.get $val) (i32.const 0))
            if 
              (i32.mul (i32.add (local.get $x) (local.get $offset_x)) (global.get $BLOCK_SIZE))
              local.set $pixel_x
              (i32.mul (i32.add (local.get $y) (local.get $offset_y)) (global.get $BLOCK_SIZE))
              local.set $pixel_y

              ;; brick color
              local.get $ctx
              (i32.mul (local.get $val) (i32.const 30))
              (i32.mul (local.get $val) (i32.const 20))
              (i32.mul (local.get $val) (i32.const 10))
              call $js_setFillColor

              local.get $ctx
              local.get $pixel_x
              local.get $pixel_y
              (i32.sub (global.get $BLOCK_SIZE) (i32.const 1))
              (i32.sub (global.get $BLOCK_SIZE) (i32.const 1))
              call $js_fillRect
            end

            (i32.add (local.get $x) (i32.const 1))
            local.set $x
            br $in_loop
          )
        )

        (i32.add (local.get $y) (i32.const 1))
        local.set $y
        br $out_loop
      )
    )
  )
 
  (global $ZERO_POS (ref $Pos) (struct.new $Pos (i32.const 0) (i32.const 0)))

  (func $draw 
    (local $ctx externref)
    (local $w i32)
    (local $h i32)

    (local.set $ctx (call $js_getCtx))

    (local.set $w (i32.mul (global.get $COLS) (global.get $BLOCK_SIZE)))
    (local.set $h (i32.mul (global.get $ROWS) (global.get $BLOCK_SIZE)))

    (call $js_setFillColor (local.get $ctx) (i32.const 0) (i32.const 0) (i32.const 0))
    (call $js_fillRect (local.get $ctx) (i32.const 0) (i32.const 0) (local.get $w) (local.get $h))

    (ref.as_non_null (global.get $map))
    (call $drawMat (global.get $ZERO_POS)) 
    
    global.get $cur
    (ref.as_non_null (struct.get $Cur $matrix))

    global.get $cur
    (call $drawMat (struct.get $Cur $pos))
  )

  (func $update (export "update") (param $time f64)
    (local $ep f64)
    (f64.sub (local.get $time) (global.get $lastTime)) 
    local.set $ep

    local.get $time
    global.set $lastTime

    (f64.add (global.get $dropCounter) (local.get $ep))
    global.set $dropCounter

    (f64.ge (global.get $dropCounter) (global.get $dropInterval))
    if 
      call $drop
      (global.set $dropCounter (f64.const 0.0))
    end
    call $draw
  )

  (func $reset
    (global.set $scores (i32.const 0))
    (global.set $lines (i32.const 0))
    (global.set $gameOver (i32.const 0))
    (call $createMat (global.get $COLS) (global.get $ROWS)) 
    global.set $map
    call $newCur
  )

  (func (export "init")
    call $reset

    global.get $cur
    global.get $SHAPES
    (array.get $ShapesType (i32.const 6))
    struct.set $Cur $matrix
  )
)
