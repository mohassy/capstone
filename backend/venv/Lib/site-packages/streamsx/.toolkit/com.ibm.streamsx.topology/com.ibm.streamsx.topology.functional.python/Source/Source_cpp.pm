# SPL_CGT_INCLUDE: ../../opt/python/codegen/py_pyTupleTosplTuple.cgt

package Source_cpp;
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
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '#include "splpy_sh.h"', "\n";
   print '#endif', "\n";
   print "\n";
   my $tkdir = $model->getContext()->getToolkitDirectory();
   my $pydir = $tkdir."/opt/python";
   
   require $pydir."/codegen/splpy.pm";
   
   # Initialize splpy.pm
   splpyInit($model);
   
   my $pyoutstyle = splpy_tuplestyle($model->getOutputPortAt(0));
   my $pywrapfunc='source_' . $pyoutstyle;
   my %cpp_tuple_types;
   print "\n";
   print "\n";
   print 'MY_OPERATOR_SCOPE::MY_OPERATOR::MY_OPERATOR() :', "\n";
   print '    funcop_(NULL),', "\n";
   print '    pyOutNames_0(NULL),', "\n";
   print '    occ_(-1)', "\n";
   print '{', "\n";
   print '    const char * wrapfn = "';
   print $pywrapfunc;
   print '";', "\n";
   # If occ parameter is positive then pass-by-ref is possible
   # Generate code to allow pass by ref but only use when
   # not connected to a PE output port.
   
    my $oc = $model->getParameterByName("outputConnections");
   
    if ($oc) {
       my $occ = $oc->getValueAt(0)->getSPLExpression();
       if ($occ > 0) {
   print "\n";
   print "\n";
   print '    if (!this->getOutputPortAt(0).isConnectedToAPEOutputPort()) {', "\n";
   print '       // pass by reference', "\n";
   print '       wrapfn = "source_object";', "\n";
   print '       occ_ = ';
   print $occ;
   print ';', "\n";
   print '    }', "\n";
       } 
    }
   print "\n";
   print "\n";
   print '    funcop_ = new SplpyFuncOp(this, SPLPY_CALLABLE_STATE_HANDLER, wrapfn);', "\n";
   print "\n";
   if ($pyoutstyle eq 'dict') {
   print "\n";
   print '  {', "\n";
   print '  SplpyGIL lock;', "\n";
   print '  pyOutNames_0 = Splpy::pyAttributeNames(getOutputPortAt(0));', "\n";
   print '  }', "\n";
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
   print '    delete funcop_;', "\n";
   print '}', "\n";
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::allPortsReady() ', "\n";
   print '{', "\n";
   print '  createThreads(1);', "\n";
   print '}', "\n";
   print ' ', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::prepareToShutdown() ', "\n";
   print '{', "\n";
   print '    funcop_->prepareToShutdown();', "\n";
   print '}', "\n";
   print "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::process(uint32_t idx)', "\n";
   print '{', "\n";
   print '#if SPLPY_OP_CR == 1', "\n";
   print '    SPL::ConsistentRegionContext *crc = static_cast<SPL::ConsistentRegionContext *>(getContext().getOptionalContext(CONSISTENT_REGION));', "\n";
   print '#endif', "\n";
   print "\n";
   print '    PyObject *pyReturnVar = NULL;', "\n";
   print "\n";
   print '    while(!getPE().getShutdownRequested()) {', "\n";
   print '        OPort0Type otuple;', "\n";
   print "\n";
   print '        bool submitTuple = false;', "\n";
   print '        bool allDone = false;', "\n";
   print "\n";
   print '#if SPLPY_OP_CR == 1', "\n";
   print '        ConsistentRegionPermit crp(crc);', "\n";
   print '#endif', "\n";
   print '        {', "\n";
   print '#if SPLPY_OP_STATE_HANDLER == 1', "\n";
   print '            SPL::AutoMutex am(mutex_);', "\n";
   print '#endif', "\n";
   print '            try {', "\n";
   print '                SplpyGIL lock;', "\n";
   print '                Py_CLEAR(pyReturnVar);', "\n";
   print '                pyReturnVar = PyObject_CallObject(funcop_->callable(), NULL);', "\n";
   print "\n";
   print '                if (pyReturnVar == NULL) {', "\n";
   print '                    // Has the iteration completed?', "\n";
   print '                    if (PyErr_Occurred() == SplpyErrors::StopIteration)', "\n";
   print '                        allDone = true;', "\n";
   print '                    else', "\n";
   print '                        throw SplpyExceptionInfo::pythonError("source");', "\n";
   print '                }', "\n";
   print '                else if (SplpyGeneral::isNone(pyReturnVar)) {', "\n";
   print '                    Py_CLEAR(pyReturnVar);', "\n";
   print '                } else {', "\n";
   print '                    submitTuple = true;', "\n";
   print "\n";
    if ($pyoutstyle eq 'pickle') { 
   print "\n";
   print '                    if (occ_ > 0) {', "\n";
   print '                        // passing by reference', "\n";
   print '                        pyTupleByRef(otuple.get___spl_po(), pyReturnVar, occ_);', "\n";
   print '                        pyReturnVar = NULL;', "\n";
   print '                    } else {', "\n";
   print "\n";
   print '                        // Use the pointer of the pickled bytes object', "\n";
   print '                        // as the blob data so we need to maintain the', "\n";
   print '                        // reference count across the submit.', "\n";
   print '                        // We decrement it on the next loop iteration', "\n";
   print '                        // which is when we natually regain the lock.', "\n";
   print '                        pySplValueUsingPyObject(otuple.get___spl_po(), pyReturnVar);', "\n";
   print '                    }', "\n";
   }
   print "\n";
    if ($pyoutstyle eq 'string') { 
   print "\n";
   print '                    pySplValueFromPyObject(otuple.get_string(), pyReturnVar);', "\n";
   }
   print "\n";
   if ($pyoutstyle eq 'dict') {
   print "\n";
   print '                    if (PyTuple_Check(pyReturnVar)) {', "\n";
   print '                        fromPyTupleToSPLTuple(pyReturnVar, otuple);', "\n";
   print '                        //Py_DECREF(pyReturnVar); // causing trouble with multiple sources in same PE, why Py_DECREF when there is Py_CLEAR in the loop?', "\n";
   print '                    } else if (PyDict_Check(pyReturnVar)) {', "\n";
   print '                        fromPyDictToSPLTuple(pyReturnVar, otuple);', "\n";
   print '                        //Py_DECREF(pyReturnVar); // causing trouble with multiple sources in same PE, why Py_DECREF when there is Py_CLEAR in the loop?', "\n";
   print '                    } else {', "\n";
   print '                        throw SplpyGeneral::generalException("submit",', "\n";
   print '                "Fatal error: Value submitted must be a Python tuple or dict.");', "\n";
   print '                   }', "\n";
   }
   print "\n";
   print '               }', "\n";
   print '           } catch (const streamsx::topology::SplpyExceptionInfo& excInfo) {', "\n";
   print '                SPLPY_OP_HANDLE_EXCEPTION_INFO_GIL(excInfo);', "\n";
   print '                continue;', "\n";
   print '           }', "\n";
   print '        }', "\n";
   print "\n";
   print '        if (submitTuple) {', "\n";
   print '            submit(otuple, 0);', "\n";
   print '        } else if (allDone) {', "\n";
   print "\n";
   print '#if SPLPY_OP_CR == 1', "\n";
   print '            // Wait until the region becomes consistent', "\n";
   print '            // before completing. If a reset occurred', "\n";
   print '            // then we need to continue the iterator which', "\n";
   print '            // might have been reset, and hence more tuples to submit.', "\n";
   print '            if (!crc->makeConsistent())', "\n";
   print '                continue;', "\n";
   print '#endif', "\n";
   print '            break;', "\n";
   print '        }', "\n";
   print '    }', "\n";
   print '}', "\n";
   print "\n";
   if ($pyoutstyle eq 'dict') {
     # In this case we don't want the function that
     # converts the Python tuple to an SPL tuple to
     # copy attributes from the input port
     my $iport;
   
     my $oport = $model->getOutputPortAt(0);
     my $oport_submission = 0;
     my $otupleType = $oport->getSPLTupleType();
     my @onames = SPL::CodeGen::Type::getAttributeNames($otupleType);
     my @otypes = SPL::CodeGen::Type::getAttributeTypes($otupleType);
   
   print "\n";
   print '// Create member function that converts Python tuple to SPL tuple', "\n";
   # Generates functions in an operator that converts a Python
   # tuple to an SPL tuple for a given port and optional to
   # submit the tuple.
   #
   # $oport must be set on entry to required output port
   # $oport_submission must be set on entry to generate submission methods.
   # $iport can be set to automatically copy input attributes to
   # output attributes when the Python tuple does not supply a value.
   
     my $itypeparam = "";
     my $itypearg = "";
     if (defined $iport) {
        $itypeparam = ", " . $iport->getCppTupleType() . " const & ituple";
        $itypearg = ", ituple";
     }
   print "\n";
   print "\n";
    if ($oport_submission) { 
   print "\n";
   print ' ', "\n";
   print '// Python tuple to SPL tuple with submission to a port', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::fromPythonToPort';
   print $oport->getIndex();
   print '(PyObject *pyTuple, ';
   print $oport->getCppTupleType();
   print ' & otuple ';
   print $itypeparam;
   print ') {', "\n";
   print "\n";
   print '  try {', "\n";
   print '    MY_OPERATOR_SCOPE::MY_OPERATOR::fromPyTupleToSPLTuple(pyTuple, otuple ';
   print $itypearg;
   print ');', "\n";
   print '  } catch (const streamsx::topology::SplpyExceptionInfo& excInfo) {', "\n";
   print '    SPLPY_OP_HANDLE_EXCEPTION_INFO(excInfo);', "\n";
   print '    return;', "\n";
   print '  }', "\n";
   print "\n";
   print '  STREAMSX_TUPLE_SUBMIT_ALLOW_THREADS(otuple, ';
   print $oport->getIndex();
   print ');', "\n";
   print '}', "\n";
   print "\n";
   print '// Python dict to SPL tuple with submission to a port.', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::fromPythonDictToPort';
   print $oport->getIndex();
   print '(PyObject *pyDict, ';
   print $oport->getCppTupleType();
   print ' & otuple ';
   print $itypeparam;
   print ') {', "\n";
   print "\n";
   print '  try {', "\n";
   print '    MY_OPERATOR_SCOPE::MY_OPERATOR::fromPyDictToSPLTuple(pyDict, otuple ';
   print $itypearg;
   print ');', "\n";
   print '  } catch (const streamsx::topology::SplpyExceptionInfo& excInfo) {', "\n";
   print '    SPLPY_OP_HANDLE_EXCEPTION_INFO(excInfo);', "\n";
   print '    return;', "\n";
   print '  }', "\n";
   print "\n";
   print '  STREAMSX_TUPLE_SUBMIT_ALLOW_THREADS(otuple, ';
   print $oport->getIndex();
   print ');', "\n";
   print '}', "\n";
   print "\n";
   }
   print "\n";
   print "\n";
   # Ensure we generate function only once for each tuple type
   my $otype = $oport->getCppTupleType();
   if (! exists $cpp_tuple_types{$otype}) {
       $cpp_tuple_types{$otype} = 1;
   print "\n";
   print "\n";
   print '// Python tuple to SPL tuple , conversion only', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::fromPyTupleToSPLTuple(PyObject *pyTuple, ';
   print $oport->getCppTupleType();
   print ' & otuple  ';
   print $itypeparam;
   print ') {', "\n";
   print "\n";
   print '  Py_ssize_t frs = PyTuple_GET_SIZE(pyTuple); ', "\n";
   print '    ', "\n";
     if (defined $iport) {
       print 'bool setAttr = false;';
     }
     my $spaces = '                  ';
     # handle nested tuples __NESTED_TUPLE__
     sub convertNestedPythonTupleToSpl {
       my $otuple = $_[0];
       my $atype = $_[1];
       my $spaces = $_[2];
       my $output_dir = $_[3]; # $model->getContext()->getOutputDirectory()
       my $gencode;
       $gencode = "\n";
       $gencode = $gencode . $spaces . "{\n";
       $gencode = $gencode . $spaces . "  PyObject *pyTuple = pyAttrValue;\n";
       my @attrTypes = SPL::CodeGen::Type::getAttributeTypes ($atype);
       my $i=0;
       for my $attrName (SPL::CodeGen::Type::getAttributeNames ($atype)) {
       $gencode = $gencode . $spaces . "  // $attrName - $attrTypes[$i]\n";
       $gencode = $gencode . $spaces . "  {\n";
       $gencode = $gencode . $spaces . "    PyObject *pyAttrValue = PyTuple_GET_ITEM(pyTuple, $i);\n";
       $gencode = $gencode . $spaces . "    if (!SplpyGeneral::isNone(pyAttrValue)) {\n";
           if (SPL::CodeGen::Type::isTuple($attrTypes[$i])) {
       $gencode = $gencode . $spaces . "      // tuple type: $attrName - $attrTypes[$i]\n";    
       $gencode = $gencode . $spaces . "      " . convertNestedPythonTupleToSpl($otuple.'.get_'.$attrName.'()', $attrTypes[$i], $spaces.'      ', $output_dir) . "\n";
           }
           elsif ((SPL::CodeGen::Type::isMap($attrTypes[$i])) && (SPL::CodeGen::Type::isTuple(SPL::CodeGen::Type::getValueType($attrTypes[$i])))) {          
       $gencode = $gencode . $spaces . "      // NOT IMPLEMENTED: map with tuple as value type: $attrName - $attrTypes[$i]\n";
           }
           elsif ((SPL::CodeGen::Type::isMap($attrTypes[$i])) && (SPL::CodeGen::Type::isList(SPL::CodeGen::Type::getValueType($attrTypes[$i]))) && (SPL::CodeGen::Type::isTuple(SPL::CodeGen::Type::getElementType(SPL::CodeGen::Type::getValueType($attrTypes[$i]))))) {          
       $gencode = $gencode . $spaces . "      // NOT SUPPORTED: map with list of tuple as value type: $attrName - $attrTypes[$i]\n";
             SPL::CodeGen::errorln("SPL type: " . $attrTypes[$i] . " is not supported for conversion from Python.");
           }
           elsif ((SPL::CodeGen::Type::isList($attrTypes[$i])) && (SPL::CodeGen::Type::isTuple(SPL::CodeGen::Type::getElementType($attrTypes[$i])))) {
             my $element_type = SPL::CodeGen::Type::getElementType($attrTypes[$i]);
       $gencode = $gencode . $spaces . "      // list of tuple: $attrName - $element_type\n";
       $gencode = $gencode . $spaces . "      int list_size = (int)PyList_Size(pyAttrValue);\n";
       $gencode = $gencode . $spaces . "      for (int list_index = 0; list_index < list_size; ++list_index) {\n";
       $gencode = $gencode . $spaces . "        " . spl_cpp_type($attrName, 'SPL::list', $element_type, $model->getContext()->getOutputDirectory()) . " se; // retrieve cpp type of tuple from generated header files\n";
       $gencode = $gencode . $spaces . "        $otuple.get_$attrName().add(se); // add tuple to list\n";
       $gencode = $gencode . $spaces . "        PyObject* v = PyList_GET_ITEM(pyAttrValue, list_index);\n";
       $gencode = $gencode . $spaces . "        " . convertNestedPythonTupleToSpl($otuple.'.get_'.$attrName.'()[list_index]', SPL::CodeGen::Type::getElementType($attrTypes[$i]), $spaces.'        ', $output_dir) . "\n";
       $gencode = $gencode . $spaces . "      }\n";    
           }
           else {                        
       $gencode = $gencode . $spaces . "      streamsx::topology::pySplValueFromPyObject($otuple.get_$attrName(), pyAttrValue);\n";
           }
       $gencode = $gencode . $spaces . "    }\n";
       $gencode = $gencode . $spaces . "  }\n";
           $i++;
       }
       $gencode = $gencode . $spaces . "}\n";
       return $gencode;
   }
   
     for (my $ai = 0; $ai < $oport->getNumberOfAttributes(); ++$ai) {
       
       my $attribute = $oport->getAttributeAt($ai);
       my $name = $attribute->getName();
       my $atype = $attribute->getSPLType();
       splToPythonConversionCheck($atype);
       
       if (defined $iport) {
                print 'setAttr = false;';
       }
   print "\n";
   print '    if (';
   print $ai;
   print ' < frs) {', "\n";
   print '         // Value from the Python function', "\n";
   print '         PyObject *pyAttrValue = PyTuple_GET_ITEM(pyTuple, ';
   print $ai;
   print ');', "\n";
   print '         if (!SplpyGeneral::isNone(pyAttrValue)) {', "\n";
   print '         ';
   my $nested_tuple = 0;
   print "\n";
   print '         ';
   if (SPL::CodeGen::Type::isList($atype)) {
                my $element_type = SPL::CodeGen::Type::getElementType($atype);  
                if (SPL::CodeGen::Type::isTuple($element_type)) {
   print ' ', "\n";
   print '             ';
   $nested_tuple = 1;
   print "\n";
   print '             // list of tuple ';
   print $name;
   print ' - ';
   print $element_type;
   print "\n";
   print '             int list_size = (int)PyList_Size(pyAttrValue);', "\n";
   print '             for (int list_index = 0; list_index < list_size; ++list_index) {', "\n";
   print '                 ';
   print spl_cpp_type($name, 'SPL::list', $element_type, $model->getContext()->getOutputDirectory());
   print ' se; // retrieve cpp type of tuple from generated header files', "\n";
   print '                 otuple.get_';
   print $name;
   print '().add(se); // add tuple to list', "\n";
   print '                 PyObject* v = PyList_GET_ITEM(pyAttrValue, list_index);', "\n";
   print '                 ';
   print(convertNestedPythonTupleToSpl('otuple.get_'.$name.'()[list_index]', $element_type, $spaces.'', $model->getContext()->getOutputDirectory()));
   print "\n";
   print '             }', "\n";
   print '           ';
   }
   print "\n";
   print '         ';
   }
   print ' ', "\n";
   print '         ';
   if (SPL::CodeGen::Type::isMap($atype)) {
                if (SPL::CodeGen::Type::isTuple(SPL::CodeGen::Type::getValueType($atype))) {
                  $nested_tuple = 1;
   print '    ', "\n";
   print '             // NOT IMPLEMENTED: map with tuple as value type ';
   print $name;
   print ' - ';
   print $atype;
   print "\n";
   print '           ';
   } elsif (SPL::CodeGen::Type::isList(SPL::CodeGen::Type::getValueType($atype))) {
                     my $element_type = SPL::CodeGen::Type::getElementType(SPL::CodeGen::Type::getValueType($atype));  
                     if (SPL::CodeGen::Type::isTuple($element_type)) {
                       $nested_tuple = 1;
                       SPL::CodeGen::errorln("SPL type: " . $atype . " is not supported for conversion from Python.");
   print ' ', "\n";
   print '             // NOT SUPPORTED: map of list of tuple ';
   print $name;
   print ' ';
   print $atype;
   print '                ', "\n";
   print '                ';
   }
   print "\n";
   print '            ';
   }
   print "\n";
   print '         ';
   }
   print "\n";
   print '         ';
   if (SPL::CodeGen::Type::isTuple($atype)) {
   print "\n";
   print '           ';
   $nested_tuple = 1;
   print "\n";
   print '             // tuple type ';
   print $name;
   print ' - ';
   print $atype;
   print "\n";
   print '             ';
   print(convertNestedPythonTupleToSpl('otuple.get_'.$name.'()', $atype, $spaces.'', $model->getContext()->getOutputDirectory()));
   print "\n";
   print '           ';
   }
   print "\n";
   print '         ';
   if ($nested_tuple == 0) {
   print "\n";
   print '             streamsx::topology::pySplValueFromPyObject(otuple.get_';
   print $name;
   print '(), pyAttrValue);', "\n";
   print '         ';
   }
   print "\n";
       if (defined $iport) {
                print 'setAttr = true;';
       }
   print "\n";
   print '         }', "\n";
   print '    }', "\n";
       if (defined $iport) {
       
       # Only copy attributes across if they match on name and type,
       # or on name and input type T and output type optional<T>
       my $matchInputAttr = $iport->getAttributeByName($name);
       if (defined $matchInputAttr) {
           my $inputType = $matchInputAttr->getSPLType();
           if (($inputType eq $atype) ||
               (hasOptionalTypesSupport() &&
                SPL::CodeGen::Type::isOptional($atype) &&
                ($inputType eq
                 SPL::CodeGen::Type::getUnderlyingType($atype)))) {
   print "\n";
   print '    if (!setAttr) {', "\n";
   print '      // value from the input attribute', "\n";
   print '      otuple.set_';
   print $name;
   print '(ituple.get_';
   print $name;
   print '());', "\n";
   print '    }', "\n";
         }
       }
      }
   print "\n";
   print '         ', "\n";
   }
    
   print "\n";
   print "\n";
   print '}', "\n";
   print "\n";
   print "\n";
   print '// Python dict to SPL tuple , conversion only', "\n";
   print 'void MY_OPERATOR_SCOPE::MY_OPERATOR::fromPyDictToSPLTuple(PyObject *pyDict, ';
   print $oport->getCppTupleType();
   print ' & otuple  ';
   print $itypeparam;
   print ') {', "\n";
   print "\n";
   print '  Py_ssize_t available = PyDict_Size(pyDict); ', "\n";
   print '    ', "\n";
     if (defined $iport) {
       print 'bool setAttr = false;';
     }
     my $spaces = '                  ';
     # handle nested tuples __NESTED_TUPLE__
     sub convertNestedPythonDictionaryToSpl {
         my $otuple = $_[0];
         my $atype = $_[1];
         my $spaces = $_[2];
         my $output_dir = $_[3]; # $model->getContext()->getOutputDirectory()
   
         my $gencode;
         $gencode = "\n";
         $gencode = $gencode . $spaces . "{\n";
         $gencode = $gencode . $spaces . "  PyObject *value = v;\n";
         $gencode = $gencode . $spaces . "  PyObject *k,*v;\n";
         $gencode = $gencode . $spaces . "  Py_ssize_t pos = 0;\n";
         $gencode = $gencode . $spaces . "  while (PyDict_Next(value, &pos, &k, &v)) {\n";
         $gencode = $gencode . $spaces . "    if (v != NULL) {\n";
         $gencode = $gencode . $spaces . "      if (!SplpyGeneral::isNone(v)) {\n";
         my @attrTypes = SPL::CodeGen::Type::getAttributeTypes ($atype);
         my $i=0;
         my $nested=0;
         for my $attrName (SPL::CodeGen::Type::getAttributeNames ($atype)) {
       	  $i++;
       	  $nested=0;
         $gencode = $gencode . $spaces . "          // attribute: $attrName - type: $attrTypes[$i-1]\n";   	  
             if (SPL::CodeGen::Type::isTuple($attrTypes[$i-1])) {
           	$nested=1;
         $gencode = $gencode . $spaces . "          if (pos == $i) { // attribute=$attrName\n";
         $gencode = $gencode . $spaces . "            // tuple type: $attrTypes[$i-1]\n";    
         $gencode = $gencode . $spaces . "            " . convertNestedPythonDictionaryToSpl($otuple.'.get_'.$attrName.'()', $attrTypes[$i-1], $spaces.'            ', $output_dir) . "\n";
         $gencode = $gencode . $spaces . "          }\n";
             }
             if (SPL::CodeGen::Type::isMap($attrTypes[$i-1])) {
               my $valueType = SPL::CodeGen::Type::getValueType($attrTypes[$i-1]);
               if (SPL::CodeGen::Type::isTuple($valueType)) {
                 $nested=1;
                 if ($otuple eq 'sv') {
                   SPL::CodeGen::errorln("SPL type: " . $atype . " is not supported for conversion from Python.");
                 }
         $gencode = $gencode . $spaces . "          if (pos == $i) { // attribute=$attrName\n";
         $gencode = $gencode . $spaces . "            // map with tuple as value type: $attrTypes[$i-1] - $valueType\n";
         $gencode = $gencode . $spaces . "            // SPL map from Python dictionary\n";
         $gencode = $gencode . $spaces . "            PyObject *value = v;\n";
         $gencode = $gencode . $spaces . "            PyObject *k,*v;\n";
         $gencode = $gencode . $spaces . "            Py_ssize_t pos = 0;\n";
         $gencode = $gencode . $spaces . "            while (PyDict_Next(value, &pos, &k, &v)) {\n";
         $gencode = $gencode . $spaces . "              ".SPL::CodeGen::Type::getKeyType($attrTypes[$i-1])." sk; // key type\n";
         $gencode = $gencode . $spaces . "              // Set the SPL key\n";
         $gencode = $gencode . $spaces . "              pySplValueFromPyObject(sk, k);\n";
         $gencode = $gencode . $spaces . "              // map[] creates the value if it does not exist\n";
         $gencode = $gencode . $spaces . "              ".spl_cpp_type($attrName, 'SPL::map', SPL::CodeGen::Type::getValueType($attrTypes[$i-1]), $output_dir)." & sv = ".$otuple.".get_".$attrName."()[sk];\n";
         $gencode = $gencode . $spaces . "              // Set the SPL value for value type\n";
         $gencode = $gencode . $spaces . "             ".convertNestedPythonDictionaryToSpl('sv', SPL::CodeGen::Type::getValueType($attrTypes[$i-1]), $spaces.'              ', $output_dir)."\n";
         $gencode = $gencode . $spaces . "            }\n";
         $gencode = $gencode . $spaces . "          }\n";
               }
               elsif (SPL::CodeGen::Type::isList($valueType)) {
                 my $elementType = SPL::CodeGen::Type::getElementType($attrTypes[$i-1]);
                 if (SPL::CodeGen::Type::isTuple($elementType)) {
                   $nested=1;
                   SPL::CodeGen::errorln("SPL type: " . $atype . " is not supported for conversion from Python.");
         $gencode = $gencode . $spaces . "          if (pos == $i) { // attribute=$attrName\n";
         $gencode = $gencode . $spaces . "            // map with list of tuple as value type: $attrTypes[$i-1] - $valueType\n";           
         $gencode = $gencode . $spaces . "          }\n";     
                 }
               }
             }
             if (SPL::CodeGen::Type::isList($attrTypes[$i-1])) {
           	my $elementType = SPL::CodeGen::Type::getElementType($attrTypes[$i-1]);
               if (SPL::CodeGen::Type::isTuple($elementType)) {
                 $nested=1;
                 if ($otuple eq 'sv') {
                   SPL::CodeGen::errorln("SPL type: " . $atype . " is not supported for conversion from Python.");
                 }
         $gencode = $gencode . $spaces . "          if (pos == $i) { // attribute=$attrName\n";
         $gencode = $gencode . $spaces . "            // list of tuple: $attrTypes[$i-1] - $elementType\n";
         $gencode = $gencode . $spaces . "            PyObject *value = v;\n";
         $gencode = $gencode . $spaces . "            int list_size = (int)PyList_Size(value);\n";
         $gencode = $gencode . $spaces . "            for (int list_index = 0; list_index < list_size; ++list_index) {\n";
         $gencode = $gencode . $spaces . "              ".spl_cpp_type($attrName, 'SPL::list', $elementType, $output_dir)." se; // retrieve cpp type of tuple from generated header files\n";
         $gencode = $gencode . $spaces . "              $otuple.get_$attrName().add(se); // add tuple to list\n";
         $gencode = $gencode . $spaces . "              PyObject* v = PyList_GET_ITEM(value, list_index);\n";
         $gencode = $gencode . $spaces . "             ".convertNestedPythonDictionaryToSpl($otuple.'.get_'.$attrName.'()[list_index]', $elementType, $spaces.'              ', $output_dir)."\n";
         $gencode = $gencode . $spaces . "            }\n";      
         $gencode = $gencode . $spaces . "          }\n";
               }
             }
             if (0 == $nested) {                        
         $gencode = $gencode . $spaces . "          if (pos == $i) { // attribute=$attrName\n";
         $gencode = $gencode . $spaces . "            // $attrTypes[$i-1]\n";
         $gencode = $gencode . $spaces . "            streamsx::topology::pySplValueFromPyObject($otuple.get_$attrName(), v);\n";
         $gencode = $gencode . $spaces . "          }\n";
             }
         }
         $gencode = $gencode . $spaces . "      }\n";
         $gencode = $gencode . $spaces . "    }\n";
         $gencode = $gencode . $spaces . "  }\n";
         $gencode = $gencode . $spaces . "}\n";
         return $gencode;
     }
   
     for (my $ai = $oport->getNumberOfAttributes() - 1; $ai >= 0; --$ai) {
       my $attribute = $oport->getAttributeAt($ai);
       my $name = $attribute->getName();
       my $atype = $attribute->getSPLType();
       splToPythonConversionCheck($atype);
       
       if (defined $iport) {
                print 'setAttr = false;';
       }
   print "\n";
   print '    // attribute name=';
   print $name;
   print ' type=';
   print $atype;
   print "\n";
   print '    if (available > 0) {', "\n";
   print '         // Value from the Python function', "\n";
   print '         PyObject *pyAttrValue = PyDict_GetItem(pyDict, PyTuple_GET_ITEM(pyOutNames_';
   print $oport->getIndex();
   print ', ';
   print $ai;
   print '));', "\n";
   print '         if (pyAttrValue != NULL) {', "\n";
   print '             --available;', "\n";
   print '             if (!SplpyGeneral::isNone(pyAttrValue)) {', "\n";
   print '               ';
   my $nested_tuple = 0;
   print "\n";
   print '               ';
   if (SPL::CodeGen::Type::isList($atype)) {
                      my $element_type = SPL::CodeGen::Type::getElementType($atype);  
                      if (SPL::CodeGen::Type::isTuple($element_type)) {
   print "\n";
   print '                     ';
   $nested_tuple = 1;
   print "\n";
   print '                  // list of tuple: ';
   print $name;
   print ' - ';
   print $element_type;
   print "\n";
   print '                  int list_size = (int)PyList_Size(pyAttrValue);', "\n";
   print '                  for (int list_index = 0; list_index < list_size; ++list_index) {', "\n";
   print '                      ';
   print spl_cpp_type($name, 'SPL::list', $element_type, $model->getContext()->getOutputDirectory());
   print ' se; // retrieve cpp type of tuple from generated header files', "\n";
   print '                      otuple.get_';
   print $name;
   print '().add(se); // add tuple to list', "\n";
   print '                      PyObject* v = PyList_GET_ITEM(pyAttrValue, list_index);', "\n";
   print '                      ';
   print(convertNestedPythonDictionaryToSpl('otuple.get_'.$name.'()[list_index]', $element_type, $spaces."          ", $model->getContext()->getOutputDirectory()));
   print "\n";
   print '                  }', "\n";
   print '                 ';
   }
   print "\n";
   print '               ';
   }
   print ' ', "\n";
   print '               ';
   if (SPL::CodeGen::Type::isMap($atype)) {
                      if (SPL::CodeGen::Type::isTuple(SPL::CodeGen::Type::getValueType($atype))) {
                        $nested_tuple = 1;
   print '    ', "\n";
   print '                  // map of tuple: ';
   print $name;
   print ' ';
   print $atype;
   print "\n";
   print '                  // SPL map from Python dictionary', "\n";
   print '                  PyObject *value = pyAttrValue;', "\n";
   print '                  PyObject *k,*v;', "\n";
   print '                  Py_ssize_t pos = 0;', "\n";
   print '                  while (PyDict_Next(value, &pos, &k, &v)) {', "\n";
   print '                      ';
   print SPL::CodeGen::Type::getKeyType($atype);
   print ' sk; // key type', "\n";
   print '                      // Set the SPL key', "\n";
   print '                      pySplValueFromPyObject(sk, k);', "\n";
   print '                      // map[] creates the value if it does not exist', "\n";
   print '                      ';
   print spl_cpp_type($name, 'SPL::map', SPL::CodeGen::Type::getValueType($atype), $model->getContext()->getOutputDirectory());
   print ' & sv = otuple.get_';
   print $name;
   print '()[sk];', "\n";
   print '                      // Set the SPL value for value type ';
   print SPL::CodeGen::Type::getValueType($atype);
   print "\n";
   print '                      ';
   print(convertNestedPythonDictionaryToSpl('sv', SPL::CodeGen::Type::getValueType($atype), $spaces."    ", $model->getContext()->getOutputDirectory()));
   print "\n";
   print '                  }', "\n";
   print '                 ';
   } elsif (SPL::CodeGen::Type::isList(SPL::CodeGen::Type::getValueType($atype))) {
                        my $element_type = SPL::CodeGen::Type::getElementType(SPL::CodeGen::Type::getValueType($atype));
                        if (SPL::CodeGen::Type::isTuple($element_type)) {
                          $nested_tuple = 1;
                          SPL::CodeGen::errorln("SPL type: " . $atype . " is not supported for conversion from Python.");
   print "\n";
   print '                  // NOT SUPPORTED: map of list of tuple: ';
   print $name;
   print ' ';
   print $atype;
   print "\n";
   print '                   ';
   }
   print "\n";
   print '                 ';
   }
   print "\n";
   print '               ';
   }
   print "\n";
   print '               ';
   if (SPL::CodeGen::Type::isTuple($atype)) {
   print "\n";
   print '                  ';
   $nested_tuple = 1;
   print "\n";
   print '                  // tuple type: ';
   print $name;
   print ' - ';
   print $atype;
   print "\n";
   print '                  PyObject *value = pyAttrValue;', "\n";
   print '                  PyObject *k,*v;', "\n";
   print '                  Py_ssize_t pos = 0;', "\n";
   print '                  while (PyDict_Next(value, &pos, &k, &v)) {', "\n";
   print '                    if (v != NULL) {', "\n";
   print '                      if (!SplpyGeneral::isNone(v)) {', "\n";
   print '                      ';
   my @attrTypes = SPL::CodeGen::Type::getAttributeTypes ($atype);
   print "\n";
   print '                      ';
   my $i=0; for my $attrName (SPL::CodeGen::Type::getAttributeNames ($atype)) { $i++;
   print "\n";
   print '                        ';
   if (SPL::CodeGen::Type::isTuple($attrTypes[$i-1])) {
   print "\n";
   print '                        if (pos == ';
   print $i;
   print ') { // attribute=';
   print $attrName;
   print "\n";
   print '                          // tuple type: ';
   print $attrTypes[$i-1];
   print "\n";
   print '                          ';
   print(convertNestedPythonDictionaryToSpl('otuple.get_'.$name.'().get_'.$attrName.'()', $attrTypes[$i-1], $spaces."        ", $model->getContext()->getOutputDirectory()));
   print "\n";
   print '                        }', "\n";
   print '                        ';
   } elsif ((SPL::CodeGen::Type::isList($attrTypes[$i-1])) && (SPL::CodeGen::Type::isTuple(SPL::CodeGen::Type::getElementType($attrTypes[$i-1])))) {
   print "\n";
   print '                        if (pos == ';
   print $i;
   print ') { // attribute=';
   print $attrName;
   print '  ', "\n";
   print '                           ';
   my $element_type = SPL::CodeGen::Type::getElementType($attrTypes[$i-1]);
   print "\n";
   print '                           PyObject *value = v;', "\n";
   print '                           // list of tuple: ';
   print $attrName;
   print ' - ';
   print $element_type;
   print "\n";
   print '                           int list_size = (int)PyList_Size(value);', "\n";
   print '                           for (int list_index = 0; list_index < list_size; ++list_index) {', "\n";
   print '                               ';
   print spl_cpp_type($attrName, 'SPL::list', $element_type, $model->getContext()->getOutputDirectory());
   print ' se; // retrieve cpp type of tuple from generated header files', "\n";
   print '                               otuple.get_';
   print $name;
   print '().get_';
   print $attrName;
   print '().add(se); // add tuple to list', "\n";
   print '                               PyObject* v = PyList_GET_ITEM(value, list_index);', "\n";
   print '                               ';
   print(convertNestedPythonDictionaryToSpl('otuple.get_'.$name.'().get_'.$attrName.'()[list_index]', $element_type, $spaces."          ", $model->getContext()->getOutputDirectory()));
   print "\n";
   print '                           }', "\n";
   print '                        }', "\n";
   print '                        ';
   } elsif ((SPL::CodeGen::Type::isMap($attrTypes[$i-1])) && (SPL::CodeGen::Type::isTuple(SPL::CodeGen::Type::getValueType($attrTypes[$i-1])))) {
   print "\n";
   print '                        if (pos == ';
   print $i;
   print ') { // attribute=';
   print $attrName;
   print "\n";
   print '                            // map with tuple as value type: ';
   print $attrName;
   print ' - ';
   print $attrTypes[$i-1];
   print "\n";
   print '                            // SPL map from Python dictionary', "\n";
   print '                            PyObject *value = v;', "\n";
   print '                            PyObject *k,*v;', "\n";
   print '                            Py_ssize_t pos = 0;', "\n";
   print '                            while (PyDict_Next(value, &pos, &k, &v)) {', "\n";
   print '                                ';
   print SPL::CodeGen::Type::getKeyType($attrTypes[$i-1]);
   print ' sk; // key type', "\n";
   print '                                // Set the SPL key', "\n";
   print '                                pySplValueFromPyObject(sk, k);', "\n";
   print '                                // map[] creates the value if it does not exist ';
   print SPL::CodeGen::Type::getValueType($attrTypes[$i-1]);
   print "\n";
   print '                                ';
   print spl_cpp_type($attrName, 'SPL::map', SPL::CodeGen::Type::getValueType($attrTypes[$i-1]), $model->getContext()->getOutputDirectory());
   print ' & sv = otuple.get_';
   print $name;
   print '().get_';
   print $attrName;
   print '()[sk];', "\n";
   print '                                // Set the SPL value for value type', "\n";
   print '                                ';
   print(convertNestedPythonDictionaryToSpl('sv', SPL::CodeGen::Type::getValueType($attrTypes[$i-1]), $spaces."              ", $model->getContext()->getOutputDirectory()));
   print "\n";
   print '                            }', "\n";
   print '                        }', "\n";
   print '                        ';
   } elsif ((SPL::CodeGen::Type::isMap($attrTypes[$i-1])) && (SPL::CodeGen::Type::isList(SPL::CodeGen::Type::getValueType($attrTypes[$i-1]))) && (SPL::CodeGen::Type::isTuple(SPL::CodeGen::Type::getElementType(SPL::CodeGen::Type::getValueType($attrTypes[$i-1]))))) {
   print "\n";
   print '                        if (pos == ';
   print $i;
   print ') { // attribute=';
   print $attrName;
   print "\n";
   print '                        	';
   SPL::CodeGen::errorln("SPL type: " . $attrTypes[$i-1] . " is not supported for conversion from Python.");
   print "\n";
   print '                            // NOT SUPPORTED: map with list of tuple as value type: $attrName - $attrTypes[$i]\\n";', "\n";
   print '                        }', "\n";
   print '                        ';
   } else {
   print '                        ', "\n";
   print '                        if (pos == ';
   print $i;
   print ') { // attribute=';
   print $attrName;
   print "\n";
   print '                          // ';
   print $attrTypes[$i-1];
   print "\n";
   print '                          streamsx::topology::pySplValueFromPyObject(otuple.get_';
   print $name;
   print '().get_';
   print $attrName;
   print '(), v);', "\n";
   print '                        }', "\n";
   print '                        ';
   }
   print "\n";
   print '                      ';
   }
   print "\n";
   print '                      }', "\n";
   print '                    }', "\n";
   print '                  }', "\n";
   print '               ';
   }
   print "\n";
   print '               ';
   if ($nested_tuple == 0) {
   print "\n";
   print '                  // ';
   print $name;
   print ' - ';
   print $atype;
   print "\n";
   print '                  streamsx::topology::pySplValueFromPyObject(otuple.get_';
   print $name;
   print '(), pyAttrValue);', "\n";
   print '               ';
   }
   print "\n";
       if (defined $iport) {
                print 'setAttr = true;';
       }
   print "\n";
   print '           }', "\n";
   print '        }', "\n";
   print '    }', "\n";
       if (defined $iport) {
       
       # Only copy attributes across if they match on name and type
       my $matchInputAttr = $iport->getAttributeByName($name);
       if (defined $matchInputAttr) {
          if ($matchInputAttr->getSPLType() eq $attribute->getSPLType()) {
   print "\n";
   print '    if (!setAttr) {', "\n";
   print '      // value from the input attribute', "\n";
   print '      otuple.set_';
   print $name;
   print '(ituple.get_';
   print $name;
   print '());', "\n";
   print '    }', "\n";
         }
       }
      }
   print "\n";
   print '         ', "\n";
   }
    
   print "\n";
   print '}', "\n";
    } 
   print "\n";
   }
   print "\n";
   SPL::CodeGen::implementationEpilogue($model);
   print "\n";
   CORE::exit $SPL::CodeGen::USER_ERROR if ($SPL::CodeGen::sawError);
}
1;
