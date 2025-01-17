; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=armv8.1m.main -mattr=+mve -enable-arm-maskedldst=true -disable-mve-tail-predication=false --verify-machineinstrs %s -o - | FileCheck %s

define dso_local i32 @mul_reduce_add(i32* noalias nocapture readonly %a, i32* noalias nocapture readonly %b, i32 %N) {
; CHECK-LABEL: mul_reduce_add:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    cmp r2, #0
; CHECK-NEXT:    itt eq
; CHECK-NEXT:    moveq r0, #0
; CHECK-NEXT:    bxeq lr
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    vmov.i32 q0, #0x0
; CHECK-NEXT:    dlstp.32 lr, r2
; CHECK-NEXT:  .LBB0_1: @ %vector.body
; CHECK-NEXT:    @ =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    vmov q1, q0
; CHECK-NEXT:    vldrw.u32 q0, [r0]
; CHECK-NEXT:    vldrw.u32 q2, [r1]
; CHECK-NEXT:    mov r3, r2
; CHECK-NEXT:    vmul.i32 q0, q2, q0
; CHECK-NEXT:    adds r0, #16
; CHECK-NEXT:    adds r1, #16
; CHECK-NEXT:    subs r2, #4
; CHECK-NEXT:    vadd.i32 q0, q0, q1
; CHECK-NEXT:    letp lr, .LBB0_1
; CHECK-NEXT:  @ %bb.2: @ %middle.block
; CHECK-NEXT:    vctp.32 r3
; CHECK-NEXT:    vpsel q0, q0, q1
; CHECK-NEXT:    vaddv.u32 r0, q0
; CHECK-NEXT:    pop {r7, pc}
entry:
  %cmp8 = icmp eq i32 %N, 0
  br i1 %cmp8, label %for.cond.cleanup, label %vector.ph

vector.ph:                                        ; preds = %entry
  %n.rnd.up = add i32 %N, 3
  %n.vec = and i32 %n.rnd.up, -4
  %trip.count.minus.1 = add i32 %N, -1
  %broadcast.splatinsert11 = insertelement <4 x i32> undef, i32 %trip.count.minus.1, i32 0
  %broadcast.splat12 = shufflevector <4 x i32> %broadcast.splatinsert11, <4 x i32> undef, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i32 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %vec.phi = phi <4 x i32> [ zeroinitializer, %vector.ph ], [ %6, %vector.body ]
  %broadcast.splatinsert = insertelement <4 x i32> undef, i32 %index, i32 0
  %broadcast.splat = shufflevector <4 x i32> %broadcast.splatinsert, <4 x i32> undef, <4 x i32> zeroinitializer
  %induction = add <4 x i32> %broadcast.splat, <i32 0, i32 1, i32 2, i32 3>
  %0 = getelementptr inbounds i32, i32* %a, i32 %index
  %1 = icmp ule <4 x i32> %induction, %broadcast.splat12
  %2 = bitcast i32* %0 to <4 x i32>*
  %wide.masked.load = call <4 x i32> @llvm.masked.load.v4i32.p0v4i32(<4 x i32>* %2, i32 4, <4 x i1> %1, <4 x i32> undef)
  %3 = getelementptr inbounds i32, i32* %b, i32 %index
  %4 = bitcast i32* %3 to <4 x i32>*
  %wide.masked.load13 = call <4 x i32> @llvm.masked.load.v4i32.p0v4i32(<4 x i32>* %4, i32 4, <4 x i1> %1, <4 x i32> undef)
  %5 = mul nsw <4 x i32> %wide.masked.load13, %wide.masked.load
  %6 = add nsw <4 x i32> %5, %vec.phi
  %index.next = add i32 %index, 4
  %7 = icmp eq i32 %index.next, %n.vec
  br i1 %7, label %middle.block, label %vector.body

middle.block:                                     ; preds = %vector.body
  %8 = select <4 x i1> %1, <4 x i32> %6, <4 x i32> %vec.phi
  %9 = call i32 @llvm.experimental.vector.reduce.add.v4i32(<4 x i32> %8)
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %middle.block, %entry
  %res.0.lcssa = phi i32 [ 0, %entry ], [ %9, %middle.block ]
  ret i32 %res.0.lcssa
}

define dso_local i32 @mul_reduce_add_const(i32* noalias nocapture readonly %a, i32 %b, i32 %N) {
; CHECK-LABEL: mul_reduce_add_const:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    cmp r2, #0
; CHECK-NEXT:    itt eq
; CHECK-NEXT:    moveq r0, #0
; CHECK-NEXT:    bxeq lr
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    vmov.i32 q0, #0x0
; CHECK-NEXT:    dlstp.32 lr, r2
; CHECK-NEXT:  .LBB1_1: @ %vector.body
; CHECK-NEXT:    @ =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    mov r1, r2
; CHECK-NEXT:    vmov q1, q0
; CHECK-NEXT:    vldrw.u32 q0, [r0]
; CHECK-NEXT:    adds r0, #16
; CHECK-NEXT:    subs r2, #4
; CHECK-NEXT:    vadd.i32 q0, q0, q1
; CHECK-NEXT:    letp lr, .LBB1_1
; CHECK-NEXT:  @ %bb.2: @ %middle.block
; CHECK-NEXT:    vctp.32 r1
; CHECK-NEXT:    vpsel q0, q0, q1
; CHECK-NEXT:    vaddv.u32 r0, q0
; CHECK-NEXT:    pop {r7, pc}
entry:
  %cmp6 = icmp eq i32 %N, 0
  br i1 %cmp6, label %for.cond.cleanup, label %vector.ph

vector.ph:                                        ; preds = %entry
  %n.rnd.up = add i32 %N, 3
  %n.vec = and i32 %n.rnd.up, -4
  %trip.count.minus.1 = add i32 %N, -1
  %broadcast.splatinsert9 = insertelement <4 x i32> undef, i32 %trip.count.minus.1, i32 0
  %broadcast.splat10 = shufflevector <4 x i32> %broadcast.splatinsert9, <4 x i32> undef, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i32 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %vec.phi = phi <4 x i32> [ zeroinitializer, %vector.ph ], [ %3, %vector.body ]
  %broadcast.splatinsert = insertelement <4 x i32> undef, i32 %index, i32 0
  %broadcast.splat = shufflevector <4 x i32> %broadcast.splatinsert, <4 x i32> undef, <4 x i32> zeroinitializer
  %induction = add <4 x i32> %broadcast.splat, <i32 0, i32 1, i32 2, i32 3>
  %0 = getelementptr inbounds i32, i32* %a, i32 %index
  %1 = icmp ule <4 x i32> %induction, %broadcast.splat10
  %2 = bitcast i32* %0 to <4 x i32>*
  %wide.masked.load = call <4 x i32> @llvm.masked.load.v4i32.p0v4i32(<4 x i32>* %2, i32 4, <4 x i1> %1, <4 x i32> undef)
  %3 = add nsw <4 x i32> %wide.masked.load, %vec.phi
  %index.next = add i32 %index, 4
  %4 = icmp eq i32 %index.next, %n.vec
  br i1 %4, label %middle.block, label %vector.body

middle.block:                                     ; preds = %vector.body
  %5 = select <4 x i1> %1, <4 x i32> %3, <4 x i32> %vec.phi
  %6 = call i32 @llvm.experimental.vector.reduce.add.v4i32(<4 x i32> %5)
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %middle.block, %entry
  %res.0.lcssa = phi i32 [ 0, %entry ], [ %6, %middle.block ]
  ret i32 %res.0.lcssa
}

define dso_local i32 @add_reduce_add_const(i32* noalias nocapture readonly %a, i32 %b, i32 %N) {
; CHECK-LABEL: add_reduce_add_const:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    cmp r2, #0
; CHECK-NEXT:    itt eq
; CHECK-NEXT:    moveq r0, #0
; CHECK-NEXT:    bxeq lr
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    vmov.i32 q0, #0x0
; CHECK-NEXT:    dlstp.32 lr, r2
; CHECK-NEXT:  .LBB2_1: @ %vector.body
; CHECK-NEXT:    @ =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    mov r1, r2
; CHECK-NEXT:    vmov q1, q0
; CHECK-NEXT:    vldrw.u32 q0, [r0]
; CHECK-NEXT:    adds r0, #16
; CHECK-NEXT:    subs r2, #4
; CHECK-NEXT:    vadd.i32 q0, q0, q1
; CHECK-NEXT:    letp lr, .LBB2_1
; CHECK-NEXT:  @ %bb.2: @ %middle.block
; CHECK-NEXT:    vctp.32 r1
; CHECK-NEXT:    vpsel q0, q0, q1
; CHECK-NEXT:    vaddv.u32 r0, q0
; CHECK-NEXT:    pop {r7, pc}
entry:
  %cmp6 = icmp eq i32 %N, 0
  br i1 %cmp6, label %for.cond.cleanup, label %vector.ph

vector.ph:                                        ; preds = %entry
  %n.rnd.up = add i32 %N, 3
  %n.vec = and i32 %n.rnd.up, -4
  %trip.count.minus.1 = add i32 %N, -1
  %broadcast.splatinsert9 = insertelement <4 x i32> undef, i32 %trip.count.minus.1, i32 0
  %broadcast.splat10 = shufflevector <4 x i32> %broadcast.splatinsert9, <4 x i32> undef, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i32 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %vec.phi = phi <4 x i32> [ zeroinitializer, %vector.ph ], [ %3, %vector.body ]
  %broadcast.splatinsert = insertelement <4 x i32> undef, i32 %index, i32 0
  %broadcast.splat = shufflevector <4 x i32> %broadcast.splatinsert, <4 x i32> undef, <4 x i32> zeroinitializer
  %induction = add <4 x i32> %broadcast.splat, <i32 0, i32 1, i32 2, i32 3>
  %0 = getelementptr inbounds i32, i32* %a, i32 %index
  %1 = icmp ule <4 x i32> %induction, %broadcast.splat10
  %2 = bitcast i32* %0 to <4 x i32>*
  %wide.masked.load = call <4 x i32> @llvm.masked.load.v4i32.p0v4i32(<4 x i32>* %2, i32 4, <4 x i1> %1, <4 x i32> undef)
  %3 = add nsw <4 x i32> %wide.masked.load, %vec.phi
  %index.next = add i32 %index, 4
  %4 = icmp eq i32 %index.next, %n.vec
  br i1 %4, label %middle.block, label %vector.body

middle.block:                                     ; preds = %vector.body
  %5 = select <4 x i1> %1, <4 x i32> %3, <4 x i32> %vec.phi
  %6 = call i32 @llvm.experimental.vector.reduce.add.v4i32(<4 x i32> %5)
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %middle.block, %entry
  %res.0.lcssa = phi i32 [ 0, %entry ], [ %6, %middle.block ]
  ret i32 %res.0.lcssa
}

define dso_local void @vector_mul_const(i32* noalias nocapture %a, i32* noalias nocapture readonly %b, i32 %c, i32 %N) {
; CHECK-LABEL: vector_mul_const:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    cmp r3, #0
; CHECK-NEXT:    it eq
; CHECK-NEXT:    popeq {r7, pc}
; CHECK-NEXT:    dlstp.32 lr, r3
; CHECK-NEXT:  .LBB3_1: @ %vector.body
; CHECK-NEXT:    @ =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    vldrw.u32 q0, [r1]
; CHECK-NEXT:    vmul.i32 q0, q0, r2
; CHECK-NEXT:    vstrw.32 q0, [r0]
; CHECK-NEXT:    adds r1, #16
; CHECK-NEXT:    adds r0, #16
; CHECK-NEXT:    subs r3, #4
; CHECK-NEXT:    letp lr, .LBB3_1
; CHECK-NEXT:  @ %bb.2: @ %for.cond.cleanup
; CHECK-NEXT:    pop {r7, pc}
entry:
  %cmp6 = icmp eq i32 %N, 0
  br i1 %cmp6, label %for.cond.cleanup, label %vector.ph

vector.ph:                                        ; preds = %entry
  %n.rnd.up = add i32 %N, 3
  %n.vec = and i32 %n.rnd.up, -4
  %trip.count.minus.1 = add i32 %N, -1
  %broadcast.splatinsert8 = insertelement <4 x i32> undef, i32 %trip.count.minus.1, i32 0
  %broadcast.splat9 = shufflevector <4 x i32> %broadcast.splatinsert8, <4 x i32> undef, <4 x i32> zeroinitializer
  %broadcast.splatinsert10 = insertelement <4 x i32> undef, i32 %c, i32 0
  %broadcast.splat11 = shufflevector <4 x i32> %broadcast.splatinsert10, <4 x i32> undef, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i32 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %broadcast.splatinsert = insertelement <4 x i32> undef, i32 %index, i32 0
  %broadcast.splat = shufflevector <4 x i32> %broadcast.splatinsert, <4 x i32> undef, <4 x i32> zeroinitializer
  %induction = add <4 x i32> %broadcast.splat, <i32 0, i32 1, i32 2, i32 3>
  %0 = getelementptr inbounds i32, i32* %b, i32 %index
  %1 = icmp ule <4 x i32> %induction, %broadcast.splat9
  %2 = bitcast i32* %0 to <4 x i32>*
  %wide.masked.load = call <4 x i32> @llvm.masked.load.v4i32.p0v4i32(<4 x i32>* %2, i32 4, <4 x i1> %1, <4 x i32> undef)
  %3 = mul nsw <4 x i32> %wide.masked.load, %broadcast.splat11
  %4 = getelementptr inbounds i32, i32* %a, i32 %index
  %5 = bitcast i32* %4 to <4 x i32>*
  call void @llvm.masked.store.v4i32.p0v4i32(<4 x i32> %3, <4 x i32>* %5, i32 4, <4 x i1> %1)
  %index.next = add i32 %index, 4
  %6 = icmp eq i32 %index.next, %n.vec
  br i1 %6, label %for.cond.cleanup, label %vector.body

for.cond.cleanup:                                 ; preds = %vector.body, %entry
  ret void
}

define dso_local void @vector_add_const(i32* noalias nocapture %a, i32* noalias nocapture readonly %b, i32 %c, i32 %N) {
; CHECK-LABEL: vector_add_const:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    cmp r3, #0
; CHECK-NEXT:    it eq
; CHECK-NEXT:    popeq {r7, pc}
; CHECK-NEXT:    dlstp.32 lr, r3
; CHECK-NEXT:  .LBB4_1: @ %vector.body
; CHECK-NEXT:    @ =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    vldrw.u32 q0, [r1]
; CHECK-NEXT:    vadd.i32 q0, q0, r2
; CHECK-NEXT:    vstrw.32 q0, [r0]
; CHECK-NEXT:    adds r1, #16
; CHECK-NEXT:    adds r0, #16
; CHECK-NEXT:    subs r3, #4
; CHECK-NEXT:    letp lr, .LBB4_1
; CHECK-NEXT:  @ %bb.2: @ %for.cond.cleanup
; CHECK-NEXT:    pop {r7, pc}
entry:
  %cmp6 = icmp eq i32 %N, 0
  br i1 %cmp6, label %for.cond.cleanup, label %vector.ph

vector.ph:                                        ; preds = %entry
  %n.rnd.up = add i32 %N, 3
  %n.vec = and i32 %n.rnd.up, -4
  %trip.count.minus.1 = add i32 %N, -1
  %broadcast.splatinsert8 = insertelement <4 x i32> undef, i32 %trip.count.minus.1, i32 0
  %broadcast.splat9 = shufflevector <4 x i32> %broadcast.splatinsert8, <4 x i32> undef, <4 x i32> zeroinitializer
  %broadcast.splatinsert10 = insertelement <4 x i32> undef, i32 %c, i32 0
  %broadcast.splat11 = shufflevector <4 x i32> %broadcast.splatinsert10, <4 x i32> undef, <4 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i32 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %broadcast.splatinsert = insertelement <4 x i32> undef, i32 %index, i32 0
  %broadcast.splat = shufflevector <4 x i32> %broadcast.splatinsert, <4 x i32> undef, <4 x i32> zeroinitializer
  %induction = add <4 x i32> %broadcast.splat, <i32 0, i32 1, i32 2, i32 3>
  %0 = getelementptr inbounds i32, i32* %b, i32 %index
  %1 = icmp ule <4 x i32> %induction, %broadcast.splat9
  %2 = bitcast i32* %0 to <4 x i32>*
  %wide.masked.load = call <4 x i32> @llvm.masked.load.v4i32.p0v4i32(<4 x i32>* %2, i32 4, <4 x i1> %1, <4 x i32> undef)
  %3 = add nsw <4 x i32> %wide.masked.load, %broadcast.splat11
  %4 = getelementptr inbounds i32, i32* %a, i32 %index
  %5 = bitcast i32* %4 to <4 x i32>*
  call void @llvm.masked.store.v4i32.p0v4i32(<4 x i32> %3, <4 x i32>* %5, i32 4, <4 x i1> %1)
  %index.next = add i32 %index, 4
  %6 = icmp eq i32 %index.next, %n.vec
  br i1 %6, label %for.cond.cleanup, label %vector.body

for.cond.cleanup:                                 ; preds = %vector.body, %entry
  ret void
}

define dso_local arm_aapcs_vfpcc void @vector_mul_vector_i8(i8* noalias nocapture %a, i8* noalias nocapture readonly %b, i8* noalias nocapture readonly %c, i32 %N) {
; CHECK-LABEL: vector_mul_vector_i8:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    push {r4, lr}
; CHECK-NEXT:    cmp r3, #0
; CHECK-NEXT:    it eq
; CHECK-NEXT:    popeq {r4, pc}
; CHECK-NEXT:    mov.w r12, #0
; CHECK-NEXT:    dlstp.8 lr, r3
; CHECK-NEXT:  .LBB5_1: @ %vector.body
; CHECK-NEXT:    @ =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    add.w r4, r1, r12
; CHECK-NEXT:    vldrb.u8 q0, [r4]
; CHECK-NEXT:    add.w r4, r2, r12
; CHECK-NEXT:    vldrb.u8 q1, [r4]
; CHECK-NEXT:    add.w r4, r0, r12
; CHECK-NEXT:    add.w r12, r12, #16
; CHECK-NEXT:    subs r3, #16
; CHECK-NEXT:    vmul.i8 q0, q1, q0
; CHECK-NEXT:    vstrb.8 q0, [r4]
; CHECK-NEXT:    letp lr, .LBB5_1
; CHECK-NEXT:  @ %bb.2: @ %for.cond.cleanup
; CHECK-NEXT:    pop {r4, pc}
entry:
  %cmp10 = icmp eq i32 %N, 0
  br i1 %cmp10, label %for.cond.cleanup, label %vector.ph

vector.ph:                                        ; preds = %entry
  %n.rnd.up = add i32 %N, 15
  %n.vec = and i32 %n.rnd.up, -16
  %trip.count.minus.1 = add i32 %N, -1
  %broadcast.splatinsert12 = insertelement <16 x i32> undef, i32 %trip.count.minus.1, i32 0
  %broadcast.splat13 = shufflevector <16 x i32> %broadcast.splatinsert12, <16 x i32> undef, <16 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i32 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %broadcast.splatinsert = insertelement <16 x i32> undef, i32 %index, i32 0
  %broadcast.splat = shufflevector <16 x i32> %broadcast.splatinsert, <16 x i32> undef, <16 x i32> zeroinitializer
  %induction = add <16 x i32> %broadcast.splat, <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
  %0 = getelementptr inbounds i8, i8* %b, i32 %index
  %1 = icmp ule <16 x i32> %induction, %broadcast.splat13
  %2 = bitcast i8* %0 to <16 x i8>*
  %wide.masked.load = call <16 x i8> @llvm.masked.load.v16i8.p0v16i8(<16 x i8>* %2, i32 1, <16 x i1> %1, <16 x i8> undef)
  %3 = getelementptr inbounds i8, i8* %c, i32 %index
  %4 = bitcast i8* %3 to <16 x i8>*
  %wide.masked.load14 = call <16 x i8> @llvm.masked.load.v16i8.p0v16i8(<16 x i8>* %4, i32 1, <16 x i1> %1, <16 x i8> undef)
  %5 = mul <16 x i8> %wide.masked.load14, %wide.masked.load
  %6 = getelementptr inbounds i8, i8* %a, i32 %index
  %7 = bitcast i8* %6 to <16 x i8>*
  call void @llvm.masked.store.v16i8.p0v16i8(<16 x i8> %5, <16 x i8>* %7, i32 1, <16 x i1> %1)
  %index.next = add i32 %index, 16
  %8 = icmp eq i32 %index.next, %n.vec
  br i1 %8, label %for.cond.cleanup, label %vector.body

for.cond.cleanup:                                 ; preds = %vector.body, %entry
  ret void
}

; Function Attrs: nofree norecurse nounwind
define dso_local arm_aapcs_vfpcc void @vector_mul_vector_i16(i16* noalias nocapture %a, i16* noalias nocapture readonly %b, i16* noalias nocapture readonly %c, i32 %N) local_unnamed_addr #0 {
; CHECK-LABEL: vector_mul_vector_i16:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    cmp r3, #0
; CHECK-NEXT:    it eq
; CHECK-NEXT:    popeq {r7, pc}
; CHECK-NEXT:    dlstp.16 lr, r3
; CHECK-NEXT:  .LBB6_1: @ %vector.body
; CHECK-NEXT:    @ =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    vldrh.u16 q0, [r1]
; CHECK-NEXT:    vldrh.u16 q1, [r2]
; CHECK-NEXT:    vmul.i16 q0, q1, q0
; CHECK-NEXT:    vstrh.16 q0, [r0]
; CHECK-NEXT:    adds r1, #16
; CHECK-NEXT:    adds r2, #16
; CHECK-NEXT:    adds r0, #16
; CHECK-NEXT:    subs r3, #8
; CHECK-NEXT:    letp lr, .LBB6_1
; CHECK-NEXT:  @ %bb.2: @ %for.cond.cleanup
; CHECK-NEXT:    pop {r7, pc}
entry:
  %cmp10 = icmp eq i32 %N, 0
  br i1 %cmp10, label %for.cond.cleanup, label %vector.ph

vector.ph:                                        ; preds = %entry
  %n.rnd.up = add i32 %N, 7
  %n.vec = and i32 %n.rnd.up, -8
  %trip.count.minus.1 = add i32 %N, -1
  %broadcast.splatinsert12 = insertelement <8 x i32> undef, i32 %trip.count.minus.1, i32 0
  %broadcast.splat13 = shufflevector <8 x i32> %broadcast.splatinsert12, <8 x i32> undef, <8 x i32> zeroinitializer
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %index = phi i32 [ 0, %vector.ph ], [ %index.next, %vector.body ]
  %broadcast.splatinsert = insertelement <8 x i32> undef, i32 %index, i32 0
  %broadcast.splat = shufflevector <8 x i32> %broadcast.splatinsert, <8 x i32> undef, <8 x i32> zeroinitializer
  %induction = add <8 x i32> %broadcast.splat, <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
  %0 = getelementptr inbounds i16, i16* %b, i32 %index
  %1 = icmp ule <8 x i32> %induction, %broadcast.splat13
  %2 = bitcast i16* %0 to <8 x i16>*
  %wide.masked.load = call <8 x i16> @llvm.masked.load.v8i16.p0v8i16(<8 x i16>* %2, i32 2, <8 x i1> %1, <8 x i16> undef)
  %3 = getelementptr inbounds i16, i16* %c, i32 %index
  %4 = bitcast i16* %3 to <8 x i16>*
  %wide.masked.load14 = call <8 x i16> @llvm.masked.load.v8i16.p0v8i16(<8 x i16>* %4, i32 2, <8 x i1> %1, <8 x i16> undef)
  %5 = mul <8 x i16> %wide.masked.load14, %wide.masked.load
  %6 = getelementptr inbounds i16, i16* %a, i32 %index
  %7 = bitcast i16* %6 to <8 x i16>*
  call void @llvm.masked.store.v8i16.p0v8i16(<8 x i16> %5, <8 x i16>* %7, i32 2, <8 x i1> %1)
  %index.next = add i32 %index, 8
  %8 = icmp eq i32 %index.next, %n.vec
  br i1 %8, label %for.cond.cleanup, label %vector.body

for.cond.cleanup:                                 ; preds = %vector.body, %entry
  ret void
}

declare <16 x i8> @llvm.masked.load.v16i8.p0v16i8(<16 x i8>*, i32 immarg, <16 x i1>, <16 x i8>)
declare <8 x i16> @llvm.masked.load.v8i16.p0v8i16(<8 x i16>*, i32 immarg, <8 x i1>, <8 x i16>)
declare <4 x i32> @llvm.masked.load.v4i32.p0v4i32(<4 x i32>*, i32 immarg, <4 x i1>, <4 x i32>)
declare void @llvm.masked.store.v16i8.p0v16i8(<16 x i8>, <16 x i8>*, i32 immarg, <16 x i1>)
declare void @llvm.masked.store.v8i16.p0v8i16(<8 x i16>, <8 x i16>*, i32 immarg, <8 x i1>)
declare void @llvm.masked.store.v4i32.p0v4i32(<4 x i32>, <4 x i32>*, i32 immarg, <4 x i1>)
declare i32 @llvm.experimental.vector.reduce.add.v4i32(<4 x i32>)

