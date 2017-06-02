ruby $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(Vim.evaluate('expand("<sfile>")')), '../lib'))

function! MegamanRuby()
ruby << EOF
  # buffer = Vim::Buffer.current
  require 'megaman'
  print $LOAD_PATH
  command = Megaman::HelloWorldCommand.new
  command.run
EOF
endfunction

highlight megamanGreen term=bold cterm=bold ctermfg=64
highlight megamanRed term=bold cterm=bold ctermfg=160

function! MegamanCallSync()
  let channel = ch_open('localhost:5000')
  " call ch_logfile('/tmp/channel.log', 'w')
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

function! MegamanCallAsync()
  let s:channel = ch_open('localhost:5000')
  call ch_logfile('/tmp/channel.log', 'w')
  let filename = expand('%')
  let msg = '{ "filename": "' . filename . '" }'
  call ch_sendexpr(s:channel, msg, {'callback': "MegamanHandler"})
endfunction

function! MegamanHandler(channel, msg)
  let response = json_decode(a:msg)
  if response['status'] == "success"
    echohl megamanGreen
  else
    echohl megamanRed
  endif
  echo response['message']
endfunction

function! s:print(response)
endfunction

command! RubyCommand call MegamanRuby()
command! TestFileSync call MegamanCallSync()
command! TestFileAsync call MegamanCallAsync()

" nnoremap <leader>f :TestFileSync<CR>
nnoremap <leader>f :TestFileAsync<CR>

nnoremap ;s :source /Users/dst/.vim/bundle/vim-megaman/plugin/megaman.vim<CR>
