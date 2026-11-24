# Classe base de todos os modelos gravados no banco de dados.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
