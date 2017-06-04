ruby $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(Vim.evaluate('expand("<sfile>")')), '../lib'))

let g:megaman_channel_log_path = '/tmp/channel.log'
let g:megaman_debug = 0
let g:megaman_port = 5000

function! MegamanRuby()
ruby << EOF
  # buffer = Vim::Buffer.current
  require 'megaman'
  print $LOAD_PATH
  command = Megaman::HelloWorldCommand.new
  command.run
EOF
endfunction

highlight MegamanSuccessMsg term=bold cterm=bold ctermfg=64
highlight MegamanErrorMsg term=bold cterm=bold ctermfg=160

function! s:open_channel()
  return ch_open('localhost:' . g:megaman_port)
endfunction

function! MegamanCallSync()
  let channel = s:open_channel()
  call ch_logfile(g:megaman_channel_log_path, 'w')
  let filename = expand('%')
  let msg = '{ "filename": "' . filename . '" }'
  let response = ch_evalexpr(channel, msg)
  let obj = json_decode(response)
  if obj['status'] == "success"
    echohl megamanGreen
  else
    echohl megamanRed
  endif
  echo obj['message']
endfunction

function! s:megaman_call_async(msg)
  let s:channel = s:open_channel()
  let json_msg = json_encode(a:msg)
  call ch_logfile(g:megaman_channel_log_path, 'w')
  call ch_sendexpr(s:channel, json_msg, {'callback': 'MegamanHandler'})
endfunction

function! MegamanHandler(channel, msg)
  let response = json_decode(a:msg)
  if response['status'] == "success"
    echohl MegamanSuccessMsg
  else
    echohl MegamanErrorMsg
  endif
  echo response['message']
  echohl None
endfunction

function! s:megaman_command(name, options)
  let msg = extend({ 'type': 'Command', 'constant_name': a:name }, a:options)
  call s:megaman_call_async(msg)
endfunction

function! MegamanTestCommand()
  let filename = getcwd() . '/' . expand('%')
  let options = { 'filename': filename }
  call s:megaman_command('Test', options)
endfunction

command! RubyCommand call MegamanRuby()
command! TestFileSync call MegamanCallSync()
command! TestFileAsync call MegamanTestCommand()

" nnoremap <leader>f :TestFileSync<CR>
nnoremap <leader>f :TestFileAsync<CR>

nnoremap ;s :source /Users/dst/.vim/bundle/vim-megaman/plugin/megaman.vim<CR>
