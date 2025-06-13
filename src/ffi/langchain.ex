defmodule Chain do
  alias LangChain.TextSplitter.RecursiveCharacterTextSplitter

  def split(content, chunk_size, chunk_overlap) do
    text_splitter =
      RecursiveCharacterTextSplitter.new!(%{
        chunk_size: chunk_size,
        chunk_overlap: chunk_overlap,
        separators: [",", "."],
        keep_separator: :end
      })

    RecursiveCharacterTextSplitter.split_text(text_splitter, content)
  end
end
