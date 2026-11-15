# Os PDFs usam a Helvetica embutida no formato PDF, que já cobre os acentos do português (Windows-1252).
# Sem isto, o Prawn avisa no log a cada documento que as fontes embutidas não têm suporte a outros alfabetos.
Prawn::Fonts::AFM.hide_m17n_warning = true
