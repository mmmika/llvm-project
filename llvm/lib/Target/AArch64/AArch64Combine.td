//=- AArch64.td - Define AArch64 Combine Rules ---------------*- tablegen -*-=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//

include "llvm/Target/GlobalISel/Combine.td"

def fconstant_to_constant : GICombineRule<
  (defs root:$root),
  (match (wip_match_opcode G_FCONSTANT):$root,
         [{ return matchFConstantToConstant(*${root}, MRI); }]),
  (apply [{ applyFConstantToConstant(*${root}); }])>;

def AArch64PreLegalizerCombinerHelper: GICombinerHelper<
  "AArch64GenPreLegalizerCombinerHelper", [all_combines,
                                           fconstant_to_constant]> {
  let DisableRuleOption = "aarch64prelegalizercombiner-disable-rule";
  let StateClass = "AArch64PreLegalizerCombinerHelperState";
  let AdditionalArguments = [];
}

// Matchdata for combines which replace a G_SHUFFLE_VECTOR with a
// target-specific opcode.
def shuffle_matchdata : GIDefMatchData<"ShuffleVectorPseudo">;

def rev : GICombineRule<
  (defs root:$root, shuffle_matchdata:$matchinfo),
  (match (wip_match_opcode G_SHUFFLE_VECTOR):$root,
         [{ return matchREV(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyShuffleVectorPseudo(*${root}, ${matchinfo}); }])
>;

def zip : GICombineRule<
  (defs root:$root, shuffle_matchdata:$matchinfo),
  (match (wip_match_opcode G_SHUFFLE_VECTOR):$root,
         [{ return matchZip(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyShuffleVectorPseudo(*${root}, ${matchinfo}); }])
>;

def uzp : GICombineRule<
  (defs root:$root, shuffle_matchdata:$matchinfo),
  (match (wip_match_opcode G_SHUFFLE_VECTOR):$root,
         [{ return matchUZP(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyShuffleVectorPseudo(*${root}, ${matchinfo}); }])
>;

def dup: GICombineRule <
  (defs root:$root, shuffle_matchdata:$matchinfo),
  (match (wip_match_opcode G_SHUFFLE_VECTOR):$root,
         [{ return matchDup(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyShuffleVectorPseudo(*${root}, ${matchinfo}); }])
>;

def trn : GICombineRule<
  (defs root:$root, shuffle_matchdata:$matchinfo),
  (match (wip_match_opcode G_SHUFFLE_VECTOR):$root,
         [{ return matchTRN(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyShuffleVectorPseudo(*${root}, ${matchinfo}); }])
>;

def ext: GICombineRule <
  (defs root:$root, shuffle_matchdata:$matchinfo),
  (match (wip_match_opcode G_SHUFFLE_VECTOR):$root,
         [{ return matchEXT(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyEXT(*${root}, ${matchinfo}); }])
>;

// Combines which replace a G_SHUFFLE_VECTOR with a target-specific pseudo
// instruction.
def shuffle_vector_pseudos : GICombineGroup<[dup, rev, ext, zip, uzp, trn]>;

def vashr_vlshr_imm_matchdata : GIDefMatchData<"int64_t">;
def vashr_vlshr_imm : GICombineRule<
  (defs root:$root, vashr_vlshr_imm_matchdata:$matchinfo),
  (match (wip_match_opcode G_ASHR, G_LSHR):$root,
          [{ return matchVAshrLshrImm(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyVAshrLshrImm(*${root}, MRI, ${matchinfo}); }])
>;

def form_duplane_matchdata :
  GIDefMatchData<"std::pair<unsigned, int>">;
def form_duplane : GICombineRule <
  (defs root:$root, form_duplane_matchdata:$matchinfo),
  (match (wip_match_opcode G_SHUFFLE_VECTOR):$root,
          [{ return matchDupLane(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyDupLane(*${root}, MRI, B, ${matchinfo}); }])
>;

def adjust_icmp_imm_matchdata :
  GIDefMatchData<"std::pair<uint64_t, CmpInst::Predicate>">;
def adjust_icmp_imm : GICombineRule <
  (defs root:$root, adjust_icmp_imm_matchdata:$matchinfo),
  (match (wip_match_opcode G_ICMP):$root,
          [{ return matchAdjustICmpImmAndPred(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyAdjustICmpImmAndPred(*${root}, ${matchinfo}, B, Observer); }])
>;

def icmp_lowering : GICombineGroup<[adjust_icmp_imm]>;

def extractvecelt_pairwise_add_matchdata : GIDefMatchData<"std::tuple<unsigned, LLT, Register>">;
def extractvecelt_pairwise_add : GICombineRule<
  (defs root:$root, extractvecelt_pairwise_add_matchdata:$matchinfo),
  (match (wip_match_opcode G_EXTRACT_VECTOR_ELT):$root,
          [{ return matchExtractVecEltPairwiseAdd(*${root}, MRI, ${matchinfo}); }]),
  (apply [{ applyExtractVecEltPairwiseAdd(*${root}, MRI, B, ${matchinfo}); }])
>;

// Post-legalization combines which should happen at all optimization levels.
// (E.g. ones that facilitate matching for the selector) For example, matching
// pseudos.
def AArch64PostLegalizerLoweringHelper
    : GICombinerHelper<"AArch64GenPostLegalizerLoweringHelper",
                       [shuffle_vector_pseudos, vashr_vlshr_imm,
                        icmp_lowering, form_duplane]> {
  let DisableRuleOption = "aarch64postlegalizerlowering-disable-rule";
}

// Post-legalization combines which are primarily optimizations.
def AArch64PostLegalizerCombinerHelper
    : GICombinerHelper<"AArch64GenPostLegalizerCombinerHelper",
                       [copy_prop, erase_undef_store, combines_for_extload,
                        sext_trunc_sextload,
                        hoist_logic_op_with_same_opcode_hands,
                        and_trivial_mask, xor_of_and_with_same_reg,
                        extractvecelt_pairwise_add]> {
  let DisableRuleOption = "aarch64postlegalizercombiner-disable-rule";
}
