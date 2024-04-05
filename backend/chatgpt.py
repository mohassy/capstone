import os

from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()
KEY = os.getenv("GPT_API_KEY")
messages = [{"role": "system", "content": """You are a group member that did their capstone project on text-to-speech AI
 models. Here is the final report detailing your research:
 
 Introduction 

The need for Text-to-Speech (TTS) technologies is proving to be in high demand. Text-to-speech technologies deal with the task of converting text inputs into speech. In the real world, Text-to-Speech technologies can be seen on a daily basis. A big example of where TTS technologies are used is during public transit announcements. On services such as GO or TTC, Text-to-Speech technologies are used to inform passengers about things such as the next station, safety, and general knowledge. Text-to-speech being used in this scenario is opposed to the method of pre-recording a human voice and playing the messages when appropriate. Text-to-speech is massively preferred in this situation for many reasons. It grants administrators the ability to tweak the TTS to say exactly what they want it to say in the event of changing conditions, which would be much easier than pre-recording new speeches. It is very cost and time-efficient, as little to no resources are required to generate lines of TTS. Given these benefits, it is clear as to why the advancement of Text-to-Speech is crucial. It is of high importance that TTS technologies are optimized so that they can be readily applied when needed. This includes the quality of speech, flow, pronunciation, speed, and more. It would be beneficial to take a look at different pretrained models, determine their quality, and analyze the basis on which each one is built. Doing so will help in the advancement and optimization of TTS technology, as well as the ease of implementation.

Objectives

Today’s state-of-the-art text-to-speech models follow a similar text-to-speech process. Most models we’ve analyzed convert text into phonemes which serve the purpose of helping the model better represent the basic sounds found in human speech. 

Figure 1.1: General Text-To-Speech Synthesis Pipeline

Next, the TTS model converts these phonemes into a mel-spectrogram representation. A mel-spectrogram has time on the x-axis, and a logarithmic scale on the y-axis and represents the magnitude of each point on the graph as a color. Mel-spectrograms are a low-level representation of speech waveform and are used in the intermediate step due to their many biases towards text-to-speech applications. Alternatively, If we tried to produce an audio waveform directly from text representation with 16-bit resolution, this would mean for each sampling period, our model would have to predict from a 216 possible outputs. Instead of this large solution space, spectrograms allow us to only be concerned about what frequencies are combined to form the desired sound and their magnitudes which is much easier to predict and learn.


Figure 1.2: An analog signal (in red) encoded to 4-bit PCM digital samples, for the TTS to generate this signal at each sample period, the model would have to predict the value of the audiowave from 24 set of possible values

Mel-spectrograms provide a second bias towards speech representation due to how they represent frequencies on a logarithmic scale. This increases the resolution and focuses on the lower end of the frequency spectrum and pays less attention to higher frequencies. This is a useful property since the human ear has a similar bias towards lower frequencies, we perceive the changes in frequency between frequencies in the lower end of the spectrum than higher frequencies. This allows the model to learn features that are more important to human perception and discard information that is less important. Next, models such as WaveNet which was developed by Google’s DeepMind are used to convert the mel-spectrograms into raw audio. Another model, HiFi-GAN more recently produces the raw audio output more than 150 times faster than autoregressive methods such as WaveNet and therefore what we used to convert the generated mel-spectrograms into audio in our experiments.

Approach and Methods

In this section we discuss the 3 best architectures which were the most impressive in our opinion survey results and processing efficiency rankings. 

FastPitch

FastPitch consists of two main components: a feed-forward transformer network and a pitch prediction module. The feed-forward transformer network takes as input a sequence of phonemes and outputs a sequence of mel-spectrograms, which are then converted into speech waveforms by a neural vocoder. The feed-forward transformer network is based on the FastSpeech model, but with some modifications, such as using convolutional layers instead of self-attention layers and adding residual connections between the encoder and the decoder.

The pitch prediction module is responsible for predicting the pitch contour of the speech from the input phonemes. The pitch prediction module is composed of a convolutional neural network (CNN) and a linear projection layer. The CNN extracts local features from the input phonemes, while the linear projection layer maps them to pitch values. The pitch prediction module can also take external pitch inputs, such as reference speech or user-defined contours, to control the pitch of the output speech.


Figure 2.1: Model Architecture of FastPitch

Tacotron 2

Tacotron 2 is a novel TTS system that combines WaveNet with a sequence-to-sequence model that predicts mel spectrograms from text. Mel spectrograms are compact representations of the acoustic characteristics of speech, which can be easily converted to linear spectrograms and then to waveforms using an inverse short-time Fourier transform (STFT). The sequence-to-sequence model consists of an encoder-decoder architecture with attention, similar to the Tacotron model. The encoder converts the input text into a sequence of hidden states, and the decoder generates the output mel spectrograms autoregressive-ly, conditioned on the encoder states and the previous outputs. The blue modules are part of the encoding phase as they convert text into a more suitable representation. The prediction from the previous time step is first passed through the Pre-Net module, this and the result of the Location Sensitive Attention module are concatenated and fed to a stack of 2 LSTM modules which predicts the target spectrogram frame. The predicted mel spectrograms are then fed into WaveNet as local conditioning inputs, along with global conditioning inputs that represent speaker embeddings. WaveNet generates the final speech waveforms at 24 kHz sampling rate and 16-bit resolution.


Figure 2.2: Model Architecture of Tacotron 2

VITs

VITs present a parallel end-to-end TTS method that generates more natural-sounding audio than current two-stage models. Method adopts variational inference augmented with normalizing flows and an adversarial training process. Also proposes a stochastic duration predictor to synthesize speech with diverse rhythms from input text. a text input can be spoken in multiple ways with different pitches and rhythms.

VITs is based on the Tacotron 2 framework, which consists of an encoder-decoder network with an attention mechanism and a WaveNet vocoder. The encoder converts the input text into a sequence of hidden states, and the decoder generates a sequence of mel-spectrograms conditioned on the encoder states. The WaveNet vocoder then synthesizes the final speech waveform from the mel-spectrograms. 

The main contribution of VITs is to introduce a Conditional Variational Autoencoder module between the encoder and the decoder, which aims to capture the latent prosodic and stylistic factors of speech. The Conditional Variational Autoencoder consists of a recognition network (or encoder) that infers a latent variable z from the input text and a target mel-spectrogram, and a prior network (or decoder) that generates z from the input text only. The latent variable z is then concatenated with the encoder states and fed to the decoder.

The Conditional Variational Autoencoder module enables the model to learn a disentangled and interpretable representation of speech, where z encodes the prosody and style, and the encoder states encode the content. Moreover, the Conditional Variational Autoencoder module allows the model to generate diverse and controllable speech by sampling different values of z from the prior network.

To further improve the naturalness and expressiveness of the generated speech, the paper also incorporates an adversarial learning scheme, where a discriminator network is trained to distinguish between real and synthetic mel-spectrograms. The discriminator provides a gradient signal to the generator (the encoder-decoder network) to encourage it to produce more realistic speech. 

Figure 2.3: Model Architecture of VITs

Design Analysis and Synthesis

Nine TTS models were implemented and run using Python to be analyzed for their quality. Each author listened to samples of each TTS model and graded them on a scale of 1 to 5 based on how human-like they sounded. The four grades were then divided by 4 for each model to obtain the Mean Opinion Score (MOS). The text input given to each model is given below:

“It’s an honor to address you today as the president of the United States. I want to begin by acknowledging the strength and resilience of our great nation. We’ve been through some incredibly challenging times, from a global pandemic to economic uncertainty, and even the effects of climate change, but together, we’ve shown the world what it means to be Americans.”

The results can be seen in Table 1 below.

Model
Mohammed
Thomas 
Laith
Andrew
Mean Opinion Score
Mean Opinion Score (Survey)
Fast Pitch
3.5
4
3
3.5
3.375
3.7
Glow
2.5
2
2.5
3
2.5
3.3
Jenny
5
4
4.5
4.5
4.5
2.9
Neural
1.5
1
1
1.5
1.25
3.35
Overflow
2.5
3
3
3
2.875
2.85
Speedy
1
1
2
2
1.5
3.8
Tacotron 2
4.5
4
4
3.5
4
3.1
VC
2.5
3
2.5
2.5
2.625
N/A
Vits
4.5
3.5
4
3.5
3.875
3.7

			     Table 3.1: Mean Opinion Score of each TTS model

As seen from the above table, Jenny obtained the highest Mean Opinion Score with a score of 4.5. Neural obtained the lowest Mean Opinion Score with a score of 1.25.




Figure 3.1: Text-to-speech public survey

Along with the mean opinion score collected from the team, a public survey was conducted between family and friends. This google form survey contained a video output for each of the tested models, and collected the data of user ratings. The final MOS result is provided on Table 1 above. Since a different text input is used for this public survey, the results were actually shockingly different to the MOS within our group. The results showed that speedy (our lowest ranking TTS) achieved the highest MOS with a rating of 3.8, while Jenny (our highest ranking TTS) only received 2.75, being the second lowest rating out of all of the models. This is interesting to show how TTS can have very different ratings when the different text input is in place. The text input given to each model is given below:

“Inside the Waystone a pair of men huddled at one corner of the bar. They drank with quiet determination, avoiding serious discussions of troubling news. In doing this they added a small, sullen silence to the larger, hollow one. It made an alloy of sorts, a counterpoint.”

Design Analysis and Synthesis cont’d

Below is the Mean Opinion scores of each model

Figure 4.1: Individual and MOS scores of each model


Figure 4.2: Ranking of TTS model MOS from least to greatest

Fast Pitch (3.375 MOS)

FastPitch is a fully parallel text to speech model based on FastSpeech. FastPitch predicts pitch contours during inference, changing these predictions can result in a more expressive utterance of the text and can give more semantic meaning behind the word. The paper claims that there is no overhead as it retains the fully-parallel Transformer architecture of FastSpeech. FastPitch's integration of fundamental frequency contours within a fully-parallel Transformer architecture significantly improving the quality and expressiveness of synthesized speech while maintaining high efficiency and speed. The FastSpeech non-autoregressive TTS model is made with a much faster mel-spectrograms generation. However, the first-generation FastSpeech TTS also had a few problems of its own. One, the student-teacher training process was complicated and hard to code. two, with the increase of speed, there comes the loss of quality due to the information loss from the teacher model. and three, the attention map was not accurately providing the information they needed. To solve the problems listed above for FastSpeech, two separate projects FastSpeech 2 and 2s are designed. For FastSpeech 2, the main focus was placed on solving the quality of the generated mel-spectrograms.  the encoder converts the phoneme embedding sequence into the phoneme hidden sequence. Then a variance adaptor is used as a second-stage coding processor to add variances such as duration, pitch, and energy to the creation of the mel-spectrograms. a total of 3 predictors are made to correspond to duration, pitch, and energy, instead of the usual single predictor just for duration. The duration predictor uses the Montreal forced alignment to extract phoneme duration, in order to improve the alignment accuracy and thus reduce the information gap between the model input and output. The pitch predictor continuous wavelet transform (CWT) is used to decompose the continuous pitch series into pitch spectrogram, and take the pitch spectrogram as the training target for the pitch predictor which is optimized with MSE loss. This is further converted back into pitch contour using inverse continuous wavelet transform (iCWT). The energy predictor computes the L2-norm of the amplitude of each short-time Fourier transform (STFT) frame as the energy. Then we quantize energy of each frame to 256 possible values uniformly, encode it into energy embedding, and add it to the expanded hidden sequence similarly to pitch. FastSpeech 2s addresses the complication of the student-teacher training process and the waveform generation accuracy. To address the student-teacher training process, this method of training is scrapped. Instead, the FastSpeech 2s directly trains the model with the original ground-truth target instead of the simplified output from the teacher. This increases the quality of the training process. Furthermore, instead of analyzing the one-to-many mapping previously only for the duration which resulted in a loss of accuracy,  information is now split into three smaller sections for duration, pitch, and energy, which are analyzed separately during testing. These phonemes are directly converted from text to waveform and tested individually to ensure a better accuracy is reached in all aspects.


Fast Pitch spoke with a good inflection and had a good flow characterized by the fast speed of talking. This fast speed of talking also hides some of its flaws such as a robotic sounding voice.

Glow (2.5 MOS)

Glow-TTS addresses the limitations of autoregressive TTS. Glow-TTS is a flow-based generative model that learns its own alignment between text and speech representations and emphasizes the advantages of parallel TTS models such as FastSpeech. In this paper, the monotonic alignment of the model is discussed, as well as its training and inference procedures. Alignments are efficiently found using Monotonic Alignment Search (MAS). Flow-based decoding is integrated into the model architecture, and TTS encoders follow Transformer structures. Detailed information about the datasets, comparisons between Glow-TTS and Tacotron 2, and training processes are provided in the experiments section. Tests show that Glow-TTS is superior to Tacotron 2 in terms of sample rate, robustness, diversity, and controllability. It is possible for Glow-TTS to produce competitive audio quality in multi-speaker settings. As a result of Glow-TTS's rapid synthesis, robustness, diversity, and support for multi-speaker scenarios, the paper concludes that it offers a promising model for practical TTS.

Glow-TTS provides a number of advantages. The Glow-TTS method achieves 15.7 times the speed of Tacotron 2, which significantly reduces the time required for inference. Applications requiring real-time performance need this speed advantage. High quality is maintained by Glow-TTS despite its ability to handle long texts. Although it is trained on short texts, it remains robust to longer texts as well. Glow-TTS features a flow-based generation of speech synthesis, making it easy to synthesize diverse kinds of speech. In addition to producing natural and expressive speech, it is able to generate various stress and intonation patterns. Because the model can learn alignment internally, it reduces external dependencies and simplifies training pipelines. Glow-TTS is compatible with multi-speaker applications, confirming its suitability for applications that rely on multiple distinct speaker voices.

Though Glow-TTS provides advantages, it also comes with a number of drawbacks. It can take a considerable amount of time and resources to implement and train flow-based generative models at scales like Glow-TTS. Using two NVIDIA V100 GPUs, the training process took approximately three days. The paper fails to provide extensive details concerning the degree of expressiveness control, despite mentioning intonation, rhythm, and speaker voices. An optimization effort is hindered by the lack of detailed computation time breakdowns provided in the paper. With Glow-TTS and WaveGlow, we can synthesize a 1-minute speech in just 1.5 seconds, with Glow-TTS contributing only 4% of the time. ReResearchers and developers who lack adequate hardware access might not be able to use Glow-TTS due to its resource requirements, which include training on multiple GPUs. Due to its particular architecture and training requirements, implementing Glow-TTS in real-world applications may pose significant engineering challenges.

Glow was robotic sounding and its speech did not flow well. It spoke with a good duration as each word was spoken at a human-like length.

Jenny (4.5 MOS)

Jenny spoke in a very natural manner with high clarity and great flow. The voice itself lacked emotion and sounded monotone. Unfortunately, no paper is provided on the Jenny TTS model causing its analysis to be low and not a lot is known about how it operates.

Neural (1.25 MOS)

Despite receiving a Mean Opinion Score (MOS) of 1.25, the Neural Text-to-Speech (TTS) model faced significant challenges. The model consistently mispronounced words, to the point of sounding like it skipped entire words. Due to the mispronunciation, the synthesized speech was not only incoherent but also disjointed and disjointed.

As a result, the model inserted pauses during speech synthesis at unpredictable and undesirable intervals. There were several pauses in the output that disrupted its natural flow, resulting in an unnatural sound. TTS's overall quality was further diminished by unexpected breaks in speech, adding an additional layer of inconsistency.

It is critical to address pronunciation accuracy, flow, and the overall coherence of synthesized speech in order to achieve the low MOS of 1.25. For the TTS model to be more effective and reliable in various applications, these aspects need to be improved in order to enhance the user experience.

Overflow (2.875 MOS)

Overflow TTS uses a Neural Hidden Markov Model and claims to require a small sample of data to be able to create their model. It also requires less updates and is less prone to “gibberish output”. The Neural HMM is a neural transducer that works well with Text to Speech aspects including speech recognition. Overflow states in their paper that the Hidden Markov model and TTS has not reached its full potential. This is also reflected in our Mean Opinion Score of the model which gave it a 2.875. The pronunciation of the model is good, but it is very jittery and it struggles at the beginning of sentences. Overflow uses a concept known as “monotonicity” which ensures that each phoneme is spoken in the correct order. Overflow uses an autoregressive model. Since this paper was written in 2023, Overflow model aims to improve on its model in the future to attempt to reach its full potential. 

Overflow struggled to pronounce the first word of each sentence. Its voice was also stuttery and jittery and it sounded like its voice was vibrating. 

Speedy (1.5 MOS)

Speedy's difficulty pronouncing certain words was indicative of his broader struggle with adapting to varied linguistic contexts. As a result of inconsistencies in the model's performance, more nuanced or specialized phrases seemed to be unable to be articulated properly. It may be difficult to use Speedy in scenarios requiring precise and accurate speech synthesis, such as those in education or the workplace. This lack of reliability could potentially limit the applicability of Speedy in these situations.

Several common words, such as "Americans" and "address," are mispronounced in the model, which raises concerns about its generalization capability. Speedy's limited pronunciation may be a major drawback for users who require clear and accurate communication with TTS technology.

The limitations of Speedy's pronunciation indicate the challenges in achieving a complex and linguistically adept TTS system, despite its advantages in training efficiency, fast inference, and high-quality audio synthesis. Speedy's overall performance would be enhanced by improvements in handling diverse vocabulary and improving pronunciation accuracy, contributing to a more versatile and reliable speech synthesis system.

Tacotron 2 (4 MOS)

In text-to-speech synthesis, Tacotron 2 is a neural network architecture. It creates mel-scale spectrograms by converting character embeddings into recurrent sequence-to-sequence feature prediction networks. A modified WaveNet model creates waveforms by combining these spectrograms into a vocoder. This model's design is validated through ablation studies, which achieve an average MOS of 4.53 from professional studies. Using mel spectrograms instead of linguistics, or duration as conditioning inputs to WaveNet is evaluated in these studies. A significant reduction in WaveNet architecture size can be achieved by employing this concise acoustic intermediate representation.
Tacotron 2 had a good flow and sound, with a couple of flaws. It mispronounced smaller words such as “we’ve” and even the letter  “a”. 

VC (2.625 MOS)

Voice conversion (VC) is achieved by extracting source content information and target speaker information. Then reconstructing waveforms with this information. VC is a technique that alters the voice of a source speaker to a target style, such as speaker identity, prosody, and emotion, while keeping the linguistic content unchanged. A typical approach of one-shot voice conversion is to disentangle content information and speaker information from source and target speech, respectively, and then use them to reconstruct the converted speech. However, this current approach normally extracts dirty content information with speaker information leaked in. while another popular text-based VC approach is to use an automatic speech recognition (ASR) model to extract phonetic posteriorgram (PPG) as content representation. However, this method also suffers from the consequence of demand for a large amount of annotated data for training, which can be costly to creators. VC proposes a text-free one-shot Voice conversion system named FreeVC, which adopts the framework of VITS for its brilliant reconstruction ability, but learns to disentangle content information without the need of text annotation.

The backbone of FreeVC is inherited from VITS, which is a CVAE augmented with GAN training. Different from VITS, the prior encoder of FreeVC takes raw waveform as input instead of text annotation, and has a different structure. The speaker embedding is extracted by a speaker encoder to perform one-shot VC. In addition, FreeVC adopts a different training strategy and inference procedure. 

VC spoke with an inconsistent tempo, as it would slow down and speed up. It had strange pauses after the words “begin” and “incredibly”.

Vits (3.875 MOS)

Vits presents a parallel end-to-end TTS method that generates more natural-sounding audio than current two-stage models. This method adopts variational inference augmented with normalizing flows and an adversarial training process. It also proposes a stochastic duration predictor to synthesize speech with diverse rhythms from input text. A text input can be spoken in multiple ways with different pitches and rhythms.

Vits spoke with good flow and clarity but had inconsistent pronunciation. It would pronounce some words flawlessly and others with great difficulty.

The time it takes for each model is noted in Table 2 below. This is important to us in choosing a TTS model to use in addition to the Mean Opinion Scores which measure quality. Table 2 gives a measure of accessibility, usability, and cost-effectiveness.

Model
Processing time
(seconds)
Real-time factor
(seconds)
Total Elapsed Time
(seconds)
Fast Pitch
1.13
0.06
2.7
Glow
0.80
0.03
1.75
Jenny
13.69
0.89
39.60
Neural
2.79
0.14
4.46
Overflow
2.60
0.13
4.22
Speedy
1.14
0.06
2.55
Tacotron 2
5.82
0.27
7.83
Vits
4.77
0.24
12.93

Table 4.1: Time taken for various TTS models 
Figure 4.3: Time taken for various TTS models II


Although Jenny had the highest Mean Opinion Score, it takes by far the most amount of time to synthesize an output. This may call for the consideration of alternative TTS models to be used such that they provide overall better quality, usability, accessibility, and cost effectiveness. After looking at the time taken for each TTS model, Tacotron 2 seems a much more valuable TTS model than it did before in terms of these overall factors.

Conclusion

In conclusion we have been able to evaluate various models such as FastPitch, Glo, Jenny, Neural, Overflow, Speedy, Tacotron 2, VC, and Vits which have all shown strengths and shortcomings. The best performing models were Tacotron 2, FastPitch and VITs which were all directly or indirectly related to DeepMind’s WaveNet model which was a huge breakthrough in text-to-speech technology. Furthermore, the time taken by each model to synthesize an output became a pivotal consideration since our ultimate goal is to build a real-time chatbot, using this criteria, it seems like transformer based models such as FastPitch performed significantly better than any other method while still retaining audio quality. Autoregressive models such as Tacotron 2, WaveNet were commendable in their performance and could still be applied to real time text to speech applications. Jenny, despite having the highest MOS of 4.5 will not be considered for our application going forward due to how processing time it requires to synthesize audio. Ultimately this detailed evaluation provides a nuanced perspective of existing state of the art text to speech technologies. These insights and gained understanding of the field and existing technologies pave the way for our next step of implementing a text to speech chatbot in the upcoming semester.

Answer the questions pretending to be a group member sharing their discoveries


"""}]


def chatgpt_process_input(text_input):
    client = OpenAI(
        api_key=KEY,
    )
    messages.append({"role": "user", "content": text_input})
    stream = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=messages,
        stream=True,

    )

    for chunk in stream:
        if chunk.choices[0].delta.content is not None:
            yield chunk.choices[0].delta.content
