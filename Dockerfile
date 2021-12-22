FROM public.ecr.aws/prima/elixir:1.12.2-2

WORKDIR /code

# Serve per avere l'owner dei file scritti dal container uguale all'utente Linux sull'host
USER app

ENTRYPOINT ["./entrypoint"]
