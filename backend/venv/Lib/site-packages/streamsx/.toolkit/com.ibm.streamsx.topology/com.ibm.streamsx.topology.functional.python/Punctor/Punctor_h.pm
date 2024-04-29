# SPL_CGT_INCLUDE: ../py_pystateful.cgt
# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_disallow_cr_trigger.cgt
# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_state.cgt

package Punctor_h;
use strict; use Cwd 'realpath';  use File::Basename;  use lib dirname(__FILE__);  use SPL::Operator::Instance::OperatorInstance; use SPL::Operator::Instance::Annotation; use SPL::Operator::Instance::Context; use SPL::Operator::Instance::Expression; use SPL::Operator::Instance::ExpressionTree; use SPL::Operator::Instance::ExpressionTreeEvaluator; use SPL::Operator::Instance::ExpressionTreeVisitor; use SPL::Operator::Instance::ExpressionTreeCppGenVisitor; use SPL::Operator::Instance::InputAttribute; use SPL::Operator::Instance::InputPort; use SPL::Operator::Instance::OutputAttribute; use SPL::Operator::Instance::OutputPort; use SPL::Operator::Instance::Parameter; use SPL::Operator::Instance::StateVariable; use SPL::Operator::Instance::TupleValue; use SPL::Operator::Instance::Window; 
sub main::generate($$) {
   my ($xml, $signature) = @_;  
   print "// $$signature\n";
   my $model = SPL::Operator::Instance::OperatorInstance->new($$xml);
   unshift @INC, dirname ($model->getContext()->getOperatorDirectory()) . "/../impl/nl/include";
   $SPL::CodeGenHelper::verboseMode = $model->getContext()->isVerboseModeOn();
    
    # State $pyStateful from functional operator parameter.
    my $pyStateful = $model->getParameterByName("pyStateful")->getValueAt(0)->getSPLExpression() eq "true" ? 1 : 0;
   print "\n";
    
    # State handling setup for Python operators.
    # Requires
    #     $pyStateful is set to 0/1 if the operator's callable is not/stateful
    #
    # Sets CPP defines:
    #     SPLPY_OP_STATE_HANDLER - Set to 1 if the operator needs a state handle.
    #     SPLPY_OP_CR - Set to 1 is the operator is in a consistent region
    #     SPLPY_CALLABLE_STATEFUL - Set to 1 if the callable is stateful
    #     SPLPY_CALLABLE_STATE_HANDLER - Set to 1 if op must preserve callable state
   
    my $isWindowed = 0;
    for (my $p = 0; $p < $model->getNumberOfInputPorts(); $p++) {
      if ($model->getInputPortAt($p)->hasWindow()) {
         $isWindowed = 1;
         last;
      }
    }
   
    my $isInConsistentRegion = $model->getContext()->getOptionalContext("ConsistentRegion") ? 1 : 0;
    my $ckptKind = $model->getContext()->getCheckpointingKind();
    my $splpy_op_stateful = ($pyStateful or $isWindowed) && ($isInConsistentRegion or $ckptKind ne "none") ? 1 : 0;
   print "\n";
   print "\n";
   print '#define SPLPY_OP_STATE_HANDLER ';
   print $splpy_op_stateful;
   print "\n";
   print '#define SPLPY_OP_CR ';
   print $isInConsistentRegion;
   print "\n";
   print '#define SPLPY_CALLABLE_STATEFUL ';
   print $pyStateful ? 1 : 0;
   print "\n";
   print '#define SPLPY_CALLABLE_STATE_HANDLER (SPLPY_OP_STATE_HANDLER && SPLPY_CALLABLE_STATEFUL)', "\n";
   print "\n";
   print '#include "splpy.h"', "\n";
   print '#include "splpy_funcop.h"', "\n";
   print "\n";
   print 'using namespace streamsx::topology;', "\n";
   print "\n";
   SPL::CodeGen::headerPrologue($model);
   print "\n";
   print "\n";
    # Python operators generally may be included in a consistent region, and
    # may be the source operator in a consistent region, but may not be the 
    # source operator in a consistent-region configured with an operator-driven
    # trigger.  This is because we currently do not support any way for a python
    # operator to trigger a consistent region drain cycle.  This file enforces
    # this rule at compile time, and should be @included in any python operator
    # unless it is designed to support triggering a consistent region.
   
   
    my $consistentRegionContext = $model->getContext()->getOptionalContext("ConsistentRegion");
    if ($consistentRegionContext && $consistentRegionContext->isTriggerOperator()) { 
      # TODO
      # For topology operators, the source location here is unhelpful, since
      # it refers to a location in a generated file that the user generally
      # cannot see.  It would be better to read the @spl_note containing
      # the original python source location and report that.
      SPL::CodeGen::exitln("The " . $model->getContext()->getClass() . " operator may not be a trigger operator for a consistent region.", $model->getContext()->getSourceLocation());
   }  
   print "\n";
   print "\n";
   print 'class MY_OPERATOR : public MY_BASE_OPERATOR', "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print ' , public SPL::StateHandler', "\n";
   print '#endif', "\n";
   print '{', "\n";
   print 'public:', "\n";
   print '  MY_OPERATOR();', "\n";
   print '  virtual ~MY_OPERATOR(); ', "\n";
   print '  void prepareToShutdown(); ', "\n";
   print '  void process(Tuple const & tuple, uint32_t port);', "\n";
   print "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '  virtual void checkpoint(SPL::Checkpoint & ckpt);', "\n";
   print '  virtual void reset(SPL::Checkpoint & ckpt);', "\n";
   print '  virtual void resetToInitialState();', "\n";
   print '#endif', "\n";
   print "\n";
   print 'private:', "\n";
   print '    SplpyOp * op() { return funcop_; }', "\n";
   print "\n";
   print '    // Members', "\n";
   print '    // Control for interaction with Python', "\n";
   print '    SplpyFuncOp *funcop_;', "\n";
   print '    ', "\n";
   print '    PyObject *pyInStyleObj_;', "\n";
   print "\n";
   print '#if SPLPY_CALLABLE_STATEFUL == 1', "\n";
   print '    SPL::Mutex mutex_;', "\n";
   print '#endif', "\n";
   print '}; ', "\n";
   print "\n";
   SPL::CodeGen::headerEpilogue($model);
   print "\n";
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
