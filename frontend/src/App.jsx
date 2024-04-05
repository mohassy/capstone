import { useState } from "react";
import { Dropdown } from 'react-bootstrap';
import "./App.css";
import chatgpt_icon from "./assets/chatGPT_icon.png";
import llama2_icon from "./assets/llama2.jpeg";
import 'bootstrap/dist/css/bootstrap.min.css';
import "@chatscope/chat-ui-kit-styles/dist/default/styles.min.css";
import {
  MainContainer,
  ChatContainer,
  Avatar,
  MessageGroup,
  ConversationHeader,
  MessageList,
  Message,
  MessageInput,
  TypingIndicator,
} from "@chatscope/chat-ui-kit-react";
function App() {
  const voices = ['Hassan', 'Thomas2', 'Laith2', 'Andrew2','Rachel', 'Drew', 'Clyde', 'Paul', 'Domi', 'Dave', 'Fin', 'Sarah', 'Antoni', 'Thomas',
    'Charlie', 'George', 'Emily', 'Elli', 'Callum', 'Patrick', 'Harry', 'Liam', 'Dorothy', 'Josh', 'Arnold', 'Charlotte',
    'Alice', 'Matilda', 'Matthew', 'James', 'Joseph', 'Jeremy', 'Michael', 'Ethan', 'Chris', 'Gigi', 'Freya', 'Brian', 'Grace',
    'Daniel', 'Lily', 'Serena', 'Adam', 'Nicole', 'Bill', 'Jessie', 'Sam', 'Glinda', 'Giovanni', 'Mimi']
  const [messages, setMessages] = useState([
    {
      message: "Hello, how may I assist you today!",
      sender: "ChatGPT",
      direction: "incoming",
    },
  ]);
  const [typing, setTyping] = useState(false);
  const [engine, setEngine] = useState("chatgpt")
  const [icon, setIcon] = useState(chatgpt_icon)
  const handleSend = async (message) => {
    const newMessage = {
      message: message,
      sender: "user",
      direction: "outgoing",
    };
    const newChatGPTMessage = {
      message: "",
      sender: "ChatGPT",
      direction: "incoming",
    }
    // send message to ChatGPT
    try {
      const response = await fetch(`http://localhost:8000/message_${engine}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ message: message }),
      });

      const reader = response.body.getReader();

      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          break;
        }
        const stringValue = String.fromCharCode.apply(null, value);
        newChatGPTMessage.message += stringValue
        // update messages state
        const newMessages = [...messages, newMessage, newChatGPTMessage];
        setMessages(newMessages);
      }
    } catch (error) {
      console.error('Error sending message:', error);
    }

  };

  const handleSelectedModel = (eventKey) => {
    if(eventKey === "chatgpt"){
      setIcon(chatgpt_icon)
    }else if(eventKey === "llama2"){
      setIcon(llama2_icon)
    }
    setEngine(eventKey);
    setMessages([
      {
        message: "Hello, how may I assist you today!",
        sender: "ChatGPT",
        direction: "incoming",
      },
    ])
  };

  const handleSelectedVoice  = async (eventKey) => {
    try{
      const response = await fetch(`http://localhost:8000/voice`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ voice: eventKey}),
      });
      console.log(response.status)
    }catch (error) {
      console.error('Error sending message:', error);
    }
  }

  return (

      <div className="App d-flex flex-column vh-100">
        <nav className="navbar navbar-dark bg-dark">
          <Dropdown onSelect={handleSelectedModel}>
            <Dropdown.Toggle variant="secondary" id="languageEngineSelector"
            style={{marginLeft: "40px", paddingLeft:"20px", paddingRight:"20px"}}>
              Language Model
            </Dropdown.Toggle>
            <Dropdown.Menu aria-labelledby="languageEngineSelector" style={{ maxHeight: '200px', overflowY: 'auto' }}>
              <Dropdown.Item eventKey="chatgpt">ChatGPT</Dropdown.Item>
              <Dropdown.Item eventKey="llama2">Llama2</Dropdown.Item>
            </Dropdown.Menu>
          </Dropdown>
          <Dropdown onSelect={handleSelectedVoice}>
            <Dropdown.Toggle variant="secondary" id="languageEngineSelector"
             style={{marginRight: "40px", paddingLeft:"20px", paddingRight:"20px"}}>
              Voice
            </Dropdown.Toggle>
            <Dropdown.Menu aria-labelledby="languageEngineSelector"  style={{ maxHeight: '200px', overflowY: 'auto' }}>
              {voices.map((voice, index) => (
                  <Dropdown.Item key={index} eventKey={voice}>{voice}</Dropdown.Item>
              ))}
            </Dropdown.Menu>
          </Dropdown>
        </nav>
        <MainContainer className={"container flex-grow-1 overflow-auto w-100"}>
          <ChatContainer>
            <ConversationHeader>
              <Avatar src={icon} name={engine === "chatgpt" ? "ChatGPT": "Llama2"}/>
              <ConversationHeader.Content userName={engine === "chatgpt" ? "ChatGPT": "Llama2"}/>
            </ConversationHeader>
            <MessageList
                typingIndicator={
                  typing ? <TypingIndicator content='Typing'/> : null
                }
            >
            {messages.map((message, i) => {
                return (
                    <MessageGroup direction={message.direction} key={i}>
                      {message.sender === "ChatGPT" ? (
                          <Avatar src={icon} name={engine === "chatgpt" ? "ChatGPT": "Llama2"}/>
                      ) : null}
                      <MessageGroup.Messages>
                        <Message key={i} model={message}/>
                      </MessageGroup.Messages>
                    </MessageGroup>
                );
              })}
            </MessageList>
            <MessageInput className={"align-self-center w-50"}
                          placeholder="Type message here"
                          onSend={handleSend}
                          attachButton={false}
            />
          </ChatContainer>
        </MainContainer>
      </div>
  );
}

export default App;
