# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
jQuery ->
  window.welcomeController = new Welcome.Controller($('#chat').data('uri'), true);

window.Welcome = {}

class Welcome.User
  constructor: (@user_name) ->
  serialize: => { user_name: @user_name }

class Welcome.Controller
  template: (message) ->
    html =
      """
      <div class="message" >
        <label class="label label-info">
          [#{message.received}] #{message.user_name}
        </label>&nbsp;
        #{message.msg_body}
      </div>
      """
    $(html)

  userListTemplate: (userList) ->
    userHtml = ""
    for user in userList
      userHtml = userHtml + "<li>#{user.user_name}</li>"
    $(userHtml)

  constructor: (url,useWebSockets) ->
    @messageQueue = []
    @dispatcher = new WebSocketRails(url,useWebSockets)
    @dispatcher.on_open = @createGuestUser
    @bindEvents()

  bindEvents: =>
    @dispatcher.bind 'new_message', @newMessage
    @dispatcher.bind 'user_list', @updateUserList
    @dispatcher.bind 'newMess', @newMessage
    @dispatcher.bind 'country', @newMessage
    @dispatcher.bind 'textMess', @newMessage
    $('input#user_name').on 'keyup', @updateUserInfo
    $('#send').on 'click', @sendMessage
    $('#test').on 'click', @sendMessageTest
    $('#green').on 'click', @sendMessageColorGreen
    $('#blue').on 'click', @sendMessageColorBlue
    $('#message').keypress (e) -> $('#send').click() if e.keyCode == 13

  newMessage: (message) =>
    @messageQueue.push message
    @shiftMessageQueue() if @messageQueue.length > 15
    @appendMessage message

  sendMessage: (event) =>
    event.preventDefault()
    message = $('#message').val()
    @dispatcher.trigger 'new_message', {user_name: @user.user_name, msg_body: message}
    $('#message').val('')
    

  sendMessageColorGreen: (event) =>
    event.preventDefault()
    message = $('#green').val()
    @dispatcher.trigger 'new_message', {user_name: @user.user_name, msg_body: "green"}
    $('#message').val('')
 
       
  sendMessageColorBlue: (event) =>
    event.preventDefault()
    @dispatcher.trigger 'blue_message', {user_name: @user.user_name, msg_body: "blue"}
    $('#message').val('')
       
  sendMessageTest: (event) =>
    event.preventDefault()
    message = $('#message2').val()
    @dispatcher.trigger 'new_message', {user_name: @user.user_name, msg_body: "9"}
    $('#message2').val('')

  updateUserList: (userList) =>
    $('#user-list').html @userListTemplate(userList)

  updateUserInfo: (event) =>
    @user.user_name = $('input#user_name').val()
    $('#username').html @user.user_name
    @dispatcher.trigger 'change_username', @user.serialize()

  appendMessage: (message) ->
    messageTemplate = @template(message)
    $('#chat').append messageTemplate
    messageTemplate.slideDown 140

  shiftMessageQueue: =>
    @messageQueue.shift()
    $('#chat div.messages:first').slideDown 100, ->
      $(this).remove()

  createGuestUser: =>
    rand_num = Math.floor(Math.random()*1000)
    @user = new Welcome.User("Guest_" + rand_num)
    $('#username').html @user.user_name
    $('input#user_name').val @user.user_name
    @dispatcher.trigger 'new_user', @user.serialize()