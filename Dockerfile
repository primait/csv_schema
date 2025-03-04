FROM public.ecr.aws/primaassicurazioni/elixir:1.15.7

WORKDIR /code

# Serve per avere l'owner dei file scritti dal container uguale all'utente Linux sull'host
USER app

ENTRYPOINT ["./entrypoint"]
