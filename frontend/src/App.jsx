import { useState, useEffect} from "react";
import "./App.css";
import chatgpt_icon from "./assets/chatGPT_icon.png";
import llama2_icon from "./assets/llama2.jpeg";
import 'bootstrap/dist/css/bootstrap.min.css';
import { FileUploader } from "react-drag-drop-files";
import "@chatscope/chat-ui-kit-styles/dist/default/styles.min.css";
import {Container, Navbar, NavDropdown, Form, Button} from "react-bootstrap"
import {
  MainContainer,
  ChatContainer,
  Avatar,
  MessageGroup,
  ConversationHeader,
  MessageList,
  Message,
  MessageInput,
  TypingIndicator
} from "@chatscope/chat-ui-kit-react";

const fileTypes = ["MP3", "M4A","WAV"];

function App() {
  const [files, setFiles] = useState([]);
  const [voices, setVoices] = useState([]);

  useEffect(() => {
    // Fetch voices from the backend
    async function fetchVoices() {
      try {
        const response = await fetch('http://localhost:8000/voices');
        if (!response.ok) {
          throw new Error('Failed to fetch voices');
        }
        const data = await response.json();
        setVoices(data);
      } catch (error) {
        console.error('Error fetching voices:', error);
      }
    }

    fetchVoices();
  }, []); // Run once on component mount
  

  const [messages, setMessages] = useState([
    {
      message: "Hello, how may I assist you?",
      sender: "assistant",
      direction: "incoming",
    },
  ]);
  const [typing, setTyping] = useState(false);
  const [engine, setEngine] = useState("chatgpt")
  const [newVoice, setNewVoice] = useState("")
  const [voice, setVoice] = useState("Hassan")
  const [icon, setIcon] = useState(chatgpt_icon)

  const handleFileChange = (uploadedFiles) => {
    const newFiles = [];
    for(let i = 0; i < uploadedFiles.length; i++){
      const reader = new FileReader();
      const file = uploadedFiles[i];
      if (file instanceof File) {
        reader.onload = (event) => {
          const fileData = new Uint8Array(event.target.result);
          newFiles.push({
            name: file.name,
            data: fileData,
          });
          // Check if all files have been processed
          if (newFiles.length === uploadedFiles.length) {
            setFiles(newFiles);
          }
        };
        // Read the file content as ArrayBuffer
        reader.readAsArrayBuffer(file);
      }
    }
  };
  const handleSend = async (message) => {
    setTyping(true)
    const newMessage = {
      message: message,
      sender: "user",
      direction: "outgoing",
    };
    const newAssistantMessage = {
      message: "",
      sender: "assistant",
      direction: "incoming",
    }
    // map messages to openai format
    let currentMessages = messages.map((message) => {
      return { role: message.sender, content: message.message };
    });
    currentMessages.push({ role: "user", content: message });
    // send messages to LLM
    try {
      const requestBody = {
        messages: currentMessages,
        voice: voice
      }
      const response = await fetch(`http://localhost:8000/${engine}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
      });

      const reader = response.body.getReader();
      setTyping(false)
      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          break;
        }
        const stringValue = String.fromCharCode.apply(null, value);
        newAssistantMessage.message += stringValue
        // update messages state, since the array is indexed, only the 'newAssistantMessage' is updated in each loop iteration
        setMessages([...messages, newMessage, newAssistantMessage]);
      }
    } catch (error) {
      console.error('Error sending message:', error);
    }
    
  };

  const handleSelectedModel = (eventKey) => {
    if(eventKey === "chatgpt"){
      setIcon(chatgpt_icon)
    }else if(eventKey === "llama"){
      setIcon(llama2_icon)
    }
    setEngine(eventKey);
    setMessages([
      {
        message: "Hello, how may I assist you?",
        sender: "assistant",
        direction: "incoming",
      },
    ])
  };

  const handleSelectedVoice  = async (eventKey) => {
    voices.forEach(voice => {
      if(voice === eventKey){
        setVoice(voice)
      }
    });
  }

  const handleNewVoice  = async (event) => {
    setNewVoice(event.target.value)
  }

  const handleCreateVoice = async () => {
    const formData = new FormData();
  
    files.forEach((file) => {
      const blob = new Blob([file.data], { type: 'audio/mpeg' });
      formData.append('files', blob, file.name);
    });
  
    try {
      // Send the request to the backend
      const response = await fetch(`http://localhost:8000/upload/${newVoice}`, {
        method: 'POST',
        body: formData,
      });
  
      // Handle the response if needed
      const responseData = await response.json();
      if(response.status === 200){
        setVoices([...voices, newVoice]);
      }else{
        console.log(responseData)
      }
    } catch (error) {
      console.error('Error sending request:', error);
    }
  };

  return (
      <Container fluid className="d-flex flex-column vh-100">
        <Navbar bg="dark" data-bs-theme="dark" className="bg-body-tertiary">
          <Container className="d-flex gap-5 justify-content-evenly" fluid>
            <NavDropdown title="Language Model"  className="text-white" id="languageEngineSelector" onSelect={handleSelectedModel}>
                <NavDropdown.Item eventKey="chatgpt">Chat GPT</NavDropdown.Item>
                <NavDropdown.Divider />
                <NavDropdown.Item eventKey="llama">Llama</NavDropdown.Item>
            </NavDropdown>
            <NavDropdown title={voice} className="text-white" id="voiceSelector" onSelect={handleSelectedVoice}>
            <Container style={{ maxHeight: '200px', overflowY: 'auto'  }}>
              {voices.map((voice, index) => (
                <NavDropdown.Item key={index} eventKey={voice}>{voice}</NavDropdown.Item>
              ))}
            </Container>
          </NavDropdown>
          </Container>
          <Container className="d-flex gap-3 justify-content-center" fluid>
            <FileUploader
              multiple={true}
              handleChange={handleFileChange}
              name="file"
              types={fileTypes}
            />
            <Form className="d-flex gap-3">
                <Form.Control
                  type="text"
                  placeholder="Enter Voice Name"
                  onChange={handleNewVoice}
                />
                <Button className="w-50" size="sm" variant="outline-success" onClick={handleCreateVoice} >Create Voice</Button>
              </Form>
          </Container>
        </Navbar>
        <MainContainer className={"container-fluid flex-grow-1 overflow-auto"}>
          <ChatContainer>
            <ConversationHeader>
              <Avatar src={icon} name={engine === "chatgpt" ? "ChatGPT": "Llama"}/>
              <ConversationHeader.Content userName={engine === "chatgpt" ? "ChatGPT": "Llama"}/>
            </ConversationHeader>
            <MessageList
                typingIndicator={
                  typing ? <TypingIndicator content='Typing'/> : null
                }
            >
            {messages.map((message, i) => {
                return (
                    <MessageGroup direction={message.direction} key={i}>
                      {message.sender === "assistant" ? (
                          <Avatar src={icon} name={engine === "chatgpt" ? "ChatGPT": "Llama"}/>
                      ) : null}
                      <MessageGroup.Messages>
                        <Message key={i} model={message}/>
                      </MessageGroup.Messages>
                    </MessageGroup>
                );
              })}
            </MessageList>
            <MessageInput className={"align-self-center w-50"} placeholder="Type message here" onSend={handleSend} attachButton={false}/>
          </ChatContainer>
        </MainContainer>
      </Container>
  );
}

export default App;
