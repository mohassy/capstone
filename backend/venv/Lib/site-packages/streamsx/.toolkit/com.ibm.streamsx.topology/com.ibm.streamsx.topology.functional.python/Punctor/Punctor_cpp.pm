# SPL_CGT_INCLUDE: ../pyspltuple2tuple.cgt
# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_splTupleCheckForBlobs.cgt
# SPL_CGT_INCLUDE: ../pyspltuple.cgt
# SPL_CGT_INCLUDE: ../pyspltuple2value.cgt
# SPL_CGT_INCLUDE: ../pyspltuple_constructor.cgt
# SPL_CGT_INCLUDE: ../pyspltuple2dict.cgt

package Punctor_cpp;
use strict; use Cwd 'realpath';  use File::Basename;  use lib dirname(__FILE__);  use SPL::Operator::Instance::OperatorInstance; use SPL::Operator::Instance::Annotation; use SPL::Operator::Instance::Context; use SPL::Operator::Instance::Expression; use SPL::Operator::Instance::ExpressionTree; use SPL::Operator::Instance::ExpressionTreeEvaluator; use SPL::Operator::Instance::ExpressionTreeVisitor; use SPL::Operator::Instance::ExpressionTreeCppGenVisitor; use SPL::Operator::Instance::InputAttribute; use SPL::Operator::Instance::InputPort; use SPL::Operator::Instance::OutputAttribute; use SPL::Operator::Instance::OutputPort; use SPL::Operator::Instance::Parameter; use SPL::Operator::Instance::StateVariable; use SPL::Operator::Instance::TupleValue; use SPL::Operator::Instance::Window; 
sub main::generate($$) {
   my ($xml, $signature) = @_;  
   print "// $$signature\n";
   my $model = SPL::Operator::Instance::OperatorInstance->new($$xml);
   unshift @INC, dirname ($model->getContext()->getOperatorDirectory()) . "/../impl/nl/include";
   $SPL::CodeGenHelper::verboseMode = $model->getContext()->isVerboseModeOn();
   SPL::CodeGen::implementationPrologue($model);
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
    # Select the Python wrapper function
    my $pywrapfunc= $pystyle_fn . '_in';
   print "\n";
   print "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '#include "splpy_sh.h"', "\n";
   print '#endif', "\n";
   print "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::MY_OPERATOR() :', "\n";
   print '   funcop_(NULL),', "\n";
   print '   pyInStyleObj_(NULL)', "\n";
   print '{', "\n";
   print '    funcop_ = new SplpyFuncOp(this, SPLPY_CALLABLE_STATEFUL, "';
   print $pywrapfunc;
   print '");', "\n";
   print "\n";
    if ($pystyle_fn eq 'dict') { 
   print "\n";
   print '#define pyInNames_ pyInStyleObj_', "\n";
   print '{', "\n";
   print '     SplpyGIL lock;', "\n";
   print '     pyInNames_ = streamsx::topology::Splpy::pyAttributeNames(', "\n";
   print '               getInputPortAt(0));', "\n";
   print '}', "\n";
    } 
   print "\n";
   print "\n";
    if ($pystyle_nt) { 
   print "\n";
   print '#define pyNamedtupleCls_ pyInStyleObj_', "\n";
   print '{', "\n";
   print '     SplpyGIL lock;', "\n";
   print '     pyNamedtupleCls_ = streamsx::topology::SplpyGeneral::callFunction(', "\n";
   print '        "streamsx.topology.runtime", "_get_namedtuple_cls",', "\n";
   print '       streamsx::topology::pyUnicode_FromUTF8("';
   print $iport->getSPLTupleType();
   print '"),', "\n";
   print '       streamsx::topology::pyUnicode_FromUTF8("';
   print substr($pystyle, 11);
   print '"));', "\n";
   print '}', "\n";
    } 
   print "\n";
   print "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '   this->getContext().registerStateHandler(*this);', "\n";
   print '#endif', "\n";
   print '}', "\n";
   print "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::~MY_OPERATOR() ', "\n";
   print '{', "\n";
   print '    {', "\n";
   print '      SplpyGIL lock;', "\n";
   print '      Py_CLEAR(pyInStyleObj_);', "\n";
   print '    }', "\n";
   print "\n";
   print '    delete funcop_;', "\n";
   print '}', "\n";
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::prepareToShutdown() ', "\n";
   print '{', "\n";
   print '    funcop_->prepareToShutdown();', "\n";
   print '}', "\n";
   print "\n";
   my $beforeParam = $model->getParameterByName("before");
   my $before = $beforeParam ? $beforeParam->getValueAt(0)->getSPLExpression() eq "true" : 1;
   my $replaceParam = $model->getParameterByName("replace");
   my $replace = $replaceParam ? $replaceParam->getValueAt(0)->getSPLExpression() eq "true" : 0;
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::process(Tuple const & tuple, uint32_t port)', "\n";
   print '{', "\n";
   print '    bool passed = false;', "\n";
   print '    {', "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '         SPL::AutoMutex am(mutex_);', "\n";
   print '#elif SPLPY_CALLABLE_STATEFUL == 1', "\n";
   print '         SPL::AutoPortMutex am(mutex_, *this);', "\n";
   print '#endif', "\n";
   print '         try {', "\n";
   print '             SplpyGIL lock;', "\n";
   print "\n";
   # Takes the input SPL tuple and converts it to
   # the arguments needed to be passed to a Python
   # functional operator
   
   # Variables that need to be set:
   
   # $pyStyle - tuple or dictionary
   # $iport - input port 
   # $inputAttrs2Py - number of attributes to pass as tuple style
   print "\n";
   print "\n";
   print '    ';
   print $iport->getCppTupleType();
   print ' const & ';
   print $iport->getCppTupleName();
   print ' = static_cast< ';
   print $iport->getCppTupleType();
   print ' const &>(tuple);', "\n";
   print "\n";
   print splpy_inputtuple2value($pystyle, $iport);
   
   if ($pystyle eq 'dict' || $pystyle eq 'tuple' || $pystyle_nt) {
   print "\n";
   # Perl Variables that need to be set:
   #
   # $iport - input port 
   #
   # $inputAttrs2Py - number of attributes to pass as tuple style
   #
   
      #Check if a blob exists in the input schema
      for (my $i = 0; $i < $inputAttrs2Py; ++$i) {
         if (typeHasBlobs($iport->getAttributeAt($i)->getSPLType())) {
   print "\n";
   print '   PYSPL_MEMORY_VIEW_CLEANUP();', "\n";
            last;
         }
      }
   print "\n";
   }
   
   if ($pystyle eq 'dict') {
   print "\n";
   # Takes the input SPL tuple and converts it to
   # as a dict to be passed to a Python functional operator
   #
   # Leaves the C++ variable value set to a PyObject * dict.
   
   # Variables that need to be set:
   # $iport - input port 
   print "\n";
   print "\n";
   print '  PyObject *value = 0;', "\n";
   print '  {', "\n";
   print '    SplpyGIL lockdict;', "\n";
   print '    PyObject * pyDict = PyDict_New();', "\n";
   print '    // convertAndAddToPythonDictionaryObject', "\n";
        for (my $i = 0; $i < $inputAttrs2Py; ++$i) {
            my $la = $iport->getAttributeAt($i);
            print convertAndAddToPythonDictionaryObject($iport->getCppTupleName(), $i, $la->getSPLType(), $la->getName(), 'pyInNames_', 'pyDict', "    ", $model->getContext()->getOutputDirectory());
        }
   print "\n";
   print '    value = pyDict;', "\n";
   print '  }', "\n";
    } elsif ($pystyle eq 'tuple' || $pystyle_nt) { 
   print "\n";
   # Takes the input SPL tuple and converts it to
   # as a tuple to be passed to a Python functional operator
   #
   # Leaves the C++ variable value set to a PyObject * tuple.
   
   # Variables that need to be set:
   # $iport - input port 
   print "\n";
   print "\n";
   print '  PyObject *value = 0;', "\n";
   print '  {', "\n";
   print '    SplpyGIL locktuple;', "\n";
   print '    PyObject * pyTuple = PyTuple_New(';
   print $inputAttrs2Py;
   print ');', "\n";
   print '    // convertAndAddToPythonTupleObject', "\n";
        for (my $i = 0; $i < $inputAttrs2Py; ++$i) {
            my $la = $iport->getAttributeAt($i);
            print convertAndAddToPythonTupleObject($iport->getCppTupleName(), $i, $la->getSPLType(), $la->getName(), "    ", $model->getContext()->getOutputDirectory());
        }
   print "\n";
    if ($pystyle_nt) { 
   print "\n";
   print '    pyTuple = streamsx::topology::SplpyGeneral::pyCallObject(pyNamedtupleCls_, pyTuple);', "\n";
    } 
   print "\n";
   print "\n";
   print '    value = pyTuple;', "\n";
   print '  }', "\n";
    } 
   print "\n";
   print "\n";
   print '             PyObject *ret = pySplProcessTuple(funcop_->callable(), value);', "\n";
   print "\n";
   print '             if (ret == NULL) {', "\n";
   print '                 throw SplpyExceptionInfo::pythonError("punctor");', "\n";
   print '             }', "\n";
   print "\n";
   print '             passed = PyObject_IsTrue(ret);', "\n";
   print "\n";
   print '             Py_DECREF(ret);', "\n";
   print "\n";
   print '         } catch (const streamsx::topology::SplpyExceptionInfo& excInfo) {', "\n";
   print '             SPLPY_OP_HANDLE_EXCEPTION_INFO_GIL(excInfo);', "\n";
   print '             return;', "\n";
   print '         }', "\n";
   print '    }', "\n";
   print '    ', "\n";
   print '    ';
   if (($before) && (!$replace)) {
   print "\n";
   print '    if (passed) {', "\n";
   print '         submit (Punctuation::WindowMarker, 0);', "\n";
   print '    }', "\n";
   print '    ';
   }
   print "\n";
   print '    ';
   if ($replace) {
   print "\n";
   print '    if (!passed) {', "\n";
   print '        submit(tuple, 0);', "\n";
   print '    }', "\n";
   print '    ';
   } else {
   print "\n";
   print '    submit(tuple, 0);', "\n";
   print '    ';
   }
   print "\n";
   print '    ';
   if ((!$before) || ($replace)) {
   print "\n";
   print '    if (passed) {', "\n";
   print '         submit (Punctuation::WindowMarker, 0);', "\n";
   print '    }', "\n";
   print '    ';
   }
   print "\n";
   print '}', "\n";
   print "\n";
   SPL::CodeGen::implementationEpilogue($model);
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
