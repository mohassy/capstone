# SPL_CGT_INCLUDE: ../pyspltuple.cgt
# SPL_CGT_INCLUDE: ../py_pystateful.cgt
# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_disallow_cr_trigger.cgt
# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_state.cgt

package Aggregate_h;
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
   print '#include <SPL/Runtime/Window/Window.h>', "\n";
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
   print '/*', "\n";
   print 'There are four preprocessor symbols that control whether and how the ', "\n";
   print 'window is partitioned:', "\n";
   print "\n";
   print 'SPLPY_PARTITION_BY_ATTRIBUTE', "\n";
   print 'If this is 1, the window is partitioned by a single attribute in the ', "\n";
   print 'schema of the input tuple.  This requires a structured schema.', "\n";
   print "\n";
   print 'SPLPY_PARTITION_BY_PYTHON', "\n";
   print 'If this is 1, the window is partitioned by a python callable.  It may', "\n";
   print 'be the name and module of a python callable object, or a serialized', "\n";
   print 'python callable.', "\n";
   print "\n";
   print 'SPLPY_PARTITION_BY_CALLABLE', "\n";
   print 'If this is 1, the window is partitioned using a serialized python callable', "\n";
   print 'object.  If this is 1, SPLPY_PARTITION_BY_PYTHON will also always be 1.', "\n";
   print "\n";
   print 'SPLPY_PARTITION_IS_STATEFUL', "\n";
   print 'If this is 1, the python callable object has a state, and the state should', "\n";
   print 'be saved and restored if checkpointing is enabled.  If this is 1, ', "\n";
   print 'SPLPY_PARTITION_BY_PYTHON will also be 1.', "\n";
   print '*/', "\n";
   print "\n";
   # Configure Windowing
    my $inputPort = $model->getInputPortAt(0); 
    my $window = $inputPort->getWindow();
    
    my $isPunctWindow = ($window->isTumbling() &&
                         ($window->getEvictionPolicyType() ==
                          $SPL::Operator::Instance::Window::PUNCT));
   
    my $partitionByParam = $model->getParameterByName("pyPartitionBy");
    my @partitionByTypes = SPL::CodeGen::getParameterCppTypes($partitionByParam);
    my $windowCppType;
    my $windowEventCppType;
    my $partitionParamName;
    if ($partitionByParam) {
      if (scalar @partitionByTypes > 1) {
        SPL::CodeGen::exitln('Only a single partition attribute is allowed.');
      }
      else {
   print "\n";
   print '#define SPLPY_PARTITION_BY_ATTRIBUTE 1', "\n";
        my $partitionByType = $partitionByTypes[0];
        $windowCppType = SPL::CodeGen::getWindowCppType($window, "PyObject *", $partitionByType);
   
        $windowEventCppType = SPL::CodeGen::getWindowEventCppType($window, "PyObject *", $partitionByType);
   
        # Validate that the tuple type contains an attribute with name 
        # matching $partitionByParam
        $partitionParamName = substr $partitionByParam->getValueAt(0)->getSPLExpression(), 1, -1;
        if (! $inputPort->getAttributeByName($partitionParamName)) {
        	SPL::CodeGen::exitln("The input port does not contain the parameter \"$partitionParamName\", which has been specified for partitioning");
        }
      }
    }
    else {
   print "\n";
   print '#define SPLPY_PARTITION_BY_ATTRIBUTE 0', "\n";
      $windowCppType = SPL::CodeGen::getWindowCppType($window,"PyObject *");
      $windowEventCppType = SPL::CodeGen::getWindowEventCppType($window,"PyObject *");
    }    
    my $partitionIsStateful = 0;
    my $partitionByName = $model->getParameterByName("pyPartitionByName");
    my $partitionByCallable = $model->getParameterByName("pyPartitionByCallable");
    if ($partitionByName) {
        $windowCppType = SPL::CodeGen::getWindowCppType($window, "PyObject *", "PyObject *");
   
        $windowEventCppType = SPL::CodeGen::getWindowEventCppType($window, "PyObject *", "PyObject *");
   
        my $partitionIsStatefulValue = $model->getParameterByName("pyPartitionIsStateful")->getValueAt(0);
        $partitionIsStateful = SPL::CodeGen::extractPerlValue($partitionIsStatefulValue->getCppExpression(), $partitionIsStatefulValue->getSPLType());
   print "\n";
   print '#define SPLPY_PARTITION_BY_PYTHON 1', "\n";
   print '#define SPLPY_PARTITION_IS_STATEFUL ';
   print $partitionIsStateful;
   print "\n";
    }
    if ($partitionByCallable) {
   print "\n";
   print '#define SPLPY_PARTITION_BY_CALLABLE 1', "\n";
    }   
   print "\n";
   print "\n";
   print '#define SPLPY_AGGREGATE_TIME_POLICIES ';
   print $window->getEvictionPolicyType() == $SPL::Operator::Instance::Window::Time || ($window->hasTriggerPolicy() && $window->getEvictionPolicyType() == $SPL::Operator::Instance::Window::Time) ? 1 : 0;
   print "\n";
   print "\n";
    # Generic setup of a variety of variables to
    # handle conversion of spl tuples to/from Python
   
    my $tkdir = $model->getContext()->getToolkitDirectory();
    my $pydir = $tkdir."/opt/python";
   
    require $pydir."/codegen/splpy.pm";
   
    # Initialize splpy.pm
    splpyInit($model);
   
    # Currently function operators only have a single input port
    # and take all the input attributes
    my $iport = $model->getInputPortAt(0);
    my $inputAttrs2Py = $iport->getNumberOfAttributes();
   
    # determine which input tuple style is being used
    my $pystyle = $model->getParameterByName("pyStyle");
    if ($pystyle) {
        $pystyle = substr($pystyle->getValueAt(0)->getSPLExpression(), 1, -1);
    } else {
        $pystyle = splpy_tuplestyle($model->getInputPortAt(0));
    }
    # $pystyle is the raw value from the operator parameter
    # $pystyle_nt is the value that defines how the function is called
    # (for style namedtuple:xxxx it is tuple)
    # $pystyle_nt is non-zero if style is namedtuple
    my $pystyle_fn = $pystyle;
    my $pystyle_nt = substr($pystyle, 0, 11) eq 'namedtuple:';
    if ($pystyle_nt) {
       $pystyle_fn = 'tuple';
    }
   print "\n";
   print "\n";
    my $pyoutstyle = splpy_tuplestyle($model->getOutputPortAt(0));
   print "\n";
   print "\n";
   print 'class MY_OPERATOR : public MY_BASE_OPERATOR,', "\n";
   print '      public ';
   print $windowEventCppType;
   print "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print ' , public SPL::StateHandler', "\n";
   print '#endif', "\n";
   print '#if SPLPY_PARTITION_BY_PYTHON == 1', "\n";
   print '  , public streamsx::topology::OperatorWithCallable', "\n";
   print '#endif', "\n";
   print '{', "\n";
   print 'public:', "\n";
   print '  typedef ';
   print $windowCppType;
   print ' WindowType;', "\n";
   print '  typedef ';
   print $windowEventCppType;
   print ' WindowEventType;', "\n";
   if ($partitionByParam) {
   print "\n";
   print '  typedef ';
   print $partitionByTypes[0];
   print ' PartitionByType;', "\n";
   print '  typedef ';
   print $inputPort->getCppTupleType();
   print ' TupleType;', "\n";
   } elsif ($partitionByName) {
   print "\n";
   print '  typedef PyObject * PartitionByType;', "\n";
   print '  typedef ';
   print $inputPort->getCppTupleType();
   print ' TupleType;', "\n";
   }
   print "\n";
   print '  MY_OPERATOR();', "\n";
   print '  virtual ~MY_OPERATOR(); ', "\n";
   print '  void prepareToShutdown(); ', "\n";
   print '  void process(Tuple const & tuple, uint32_t port);', "\n";
   print '  void process(Punctuation const & punct, uint32_t port);', "\n";
   print "\n";
   if($isPunctWindow) {
   print "\n";
   print '  void onEmptyWindowPunctEvent(WindowEventType::WindowType & window);', "\n";
   }
   print '  ', "\n";
    if ($window->isSliding()) {
   print "\n";
   print '  void onWindowTriggerEvent(', "\n";
   print '     WindowEventType::WindowType & window, WindowEventType::PartitionType const& key);', "\n";
   print '  void afterTupleEvictionEvent(', "\n";
   print '     WindowEventType::WindowType & window,  WindowEventType::TupleType & tuple,', "\n";
   print '     WindowEventType::PartitionType const & partition);', "\n";
   }
   print "\n";
    if ($window->isTumbling()) {
   print "\n";
   print '  void beforeWindowFlushEvent(', "\n";
   print '     WindowEventType::WindowType & window, WindowEventType::PartitionType const& key);', "\n";
   }
   print "\n";
   print '#if SPLPY_PARTITION_BY_PYTHON == 1', "\n";
   print '  void onWindowPartitionEviction(WindowEventType::WindowType & window, WindowEventType::PartitionIterator begin, WindowEventType::PartitionIterator end);', "\n";
   print '#endif', "\n";
   print "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '  virtual void drain();', "\n";
   print '  virtual void checkpoint(SPL::Checkpoint & ckpt);', "\n";
   print '  virtual void reset(SPL::Checkpoint & ckpt);', "\n";
   print '  virtual void resetToInitialState();', "\n";
   print "\n";
   print '  void onCheckpointEvent(SPL::Checkpoint & ckpt) const {op()->checkpoint(ckpt);}', "\n";
   print '  void onResetEvent(SPL::Checkpoint & ckpt) {op()->reset(ckpt);}', "\n";
   print '  void onResetToInitialStateEvent() {op()->resetToInitialState();}', "\n";
   print '#endif', "\n";
   print "\n";
   print '#if SPLPY_PARTITION_BY_PYTHON == 1', "\n";
   print '  void setCallable(PyObject * callable);', "\n";
   print '  void clearCallable();', "\n";
   print '#endif', "\n";
   print "\n";
   print 'private:', "\n";
   if ($pyoutstyle eq 'dict') {
   print "\n";
   print '    void fromPyTupleToSPLTuple(PyObject *pyDict, OPort0Type & otuple);', "\n";
   print '    void fromPyDictToSPLTuple(PyObject *pyTuple, OPort0Type & otuple);', "\n";
   }
   print "\n";
   print '  ', "\n";
   print '    SplpyOp * op() const { return funcop_; }', "\n";
    if ($window->isTumbling()) {
   print "\n";
   print '   void aggregateRemaining();', "\n";
   }
   print "\n";
   print "\n";
   print '    const SPL::rstring & param(const char *name) const {', "\n";
   print '        return getParameterValues(name)[0]->getValue();', "\n";
   print '    }', "\n";
   print "\n";
   if ($partitionByParam) {
   print "\n";
   print '    PartitionByType const & getPartitionValue(TupleType const & tuple) const {', "\n";
   print '      return tuple.get_';
   print $partitionParamName;
   print '();', "\n";
   print '    }', "\n";
   } elsif ($partitionByName) {
   print "\n";
   print '    PyObject * getPartitionValue(PyObject * tuple) const;', "\n";
   }
   print "\n";
   print "\n";
   print '    // Members', "\n";
   print '    // Control for interaction with Python', "\n";
   print '    SplpyFuncOp *funcop_;', "\n";
   print '    PyObject *spl_in_object_out;', "\n";
   print '    ', "\n";
   print '    PyObject *pyInStyleObj_;', "\n";
   if ($pyoutstyle eq 'dict') {
   print '    ', "\n";
   print '    PyObject *pyOutNames_0;', "\n";
   }
   print '    ', "\n";
   print "\n";
   print '    PyObject *loads;', "\n";
   print "\n";
   print '    // Number of output connections when passing by ref', "\n";
   print '    // -1 when cannot pass by ref', "\n";
   print '    int32_t occ_;', "\n";
   print "\n";
   print '    // Window definition', "\n";
   print '    WindowType window_;	       ', "\n";
   print "\n";
   print '    Metric& _partitionCount;', "\n";
   print "\n";
   print '#if SPLPY_AGGREGATE_TIME_POLICIES == 0', "\n";
   print '    // Locking is through window acquire data when', "\n";
   print '    // there are time policies', "\n";
   print '    SPL::Mutex mutex_;', "\n";
   print '#endif', "\n";
   print '#if SPLPY_PARTITION_IS_STATEFUL == 1', "\n";
   print '    streamsx::topology::SplpyOpStateHandlerImpl * partitionStateHandler_;', "\n";
   print '#endif', "\n";
   print '}; ', "\n";
   print "\n";
   SPL::CodeGen::headerEpilogue($model);
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
