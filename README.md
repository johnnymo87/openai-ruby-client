## openai-ruby-client

This is just a personal script for how I use [the `openai-ruby` gem](https://github.com/alexrudall/ruby-openai) to interact with OpenAI's API, building and sending a prompt to a reason model, e.g. [the `o1` model](https://platform.openai.com/docs/models/o1). To see if you have access to it, check like so:

```bash
curl https://api.openai.com/v1/models -H "Authorization: Bearer $OPENAI_ACCESS_TOKEN"
```


## Install

1. Install or update `rbenv` (and `ruby-build` to get access to recent releases of python).
   ```
   brew update && brew install ruby-build rbenv
   brew update && brew upgrade ruby-build rbenv
   ```
1. Install ruby.
   ```
   rbenv install $(cat ./.ruby-version)
   ```
1. Install ruby gems.
   ```
   bundle
   ```

### Environment Variables

This application requires [an OpenAI API key](https://platform.openai.com/docs/quickstart). You can set it as an `OPENAI_ACCESS_TOKEN` environment variable in your shell or in [an `.envrc` file](https://github.com/direnv/direnv). Below are steps for how to use `direnv` to manage environment variables, but you can also simply set the environment variable in your shell.

1. Install `direnv` and configure your shell to enable automatic environment variable loading.
   ```
   brew install direnv
   ```
1. Update your dotfiles to use the direnv hook.
   ```
   # in e.g. ~/.bash_profile

   if which direnv > /dev/null; then
     eval "$(direnv hook bash)"
   fi
   ```
   * If you use zsh instead of bash, replace `direnv hook bash` with `direnv hook zsh`. See [the hooks documentation page in the direnv GitHub repository](https://github.com/direnv/direnv/blob/master/docs/hook.md) for more details.
1. Copy `.envrc.example` to `.envrc`.
   ```
   cp .envrc.example .envrc
   ```
1. Fill out `.envrc`.
1. Source the environment variables defined in `.envrc`.
   ```
   direnv allow
   ```

## Run

Write a prompt in a file in the `prompts/` directory, e.g. `prompts/reasoning-model-000001`. Consider using [this script](https://gist.github.com/johnnymo87/4701b6671730768ba95f19a5ee29a177) to merge many files into one in a way that's useful when prompting.

There's an `reasoning_model_client.rb` file. Use it to execute the prompt.
```
bundle exec ruby reasoning_model_client.rb execute prompts/reasoning-model-000001
```
The result will be in the `log/` directory. There's no support for follow up prompts, so if there's anything from the result that you want to use in a follow up prompt, you'll have to copy it manually.

## Contributing

If you'd like to contribute to the project, please feel free to submit a pull request or open an issue to discuss your ideas.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
