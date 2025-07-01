QUERY load_docs_rag(chapters: [{ id: I64, subchapters: [{ title: String, content: String, chunks: [{chunk: String, vector: [F64]}]}] }]) =>
    FOR {id, subchapters} IN chapters {
        chapter_node <- AddN<Chapter>({ chapter_index: id })
        FOR {title, content, chunks} IN subchapters {
            subchapter_node <- AddN<SubChapter>({ title: title, content: content })
            AddE<Contains>::From(chapter_node)::To(subchapter_node)
            FOR {chunk, vector} IN chunks {
                vec <- AddV<Embedding>(vector)
                AddE<EmbeddingOf>({chunk: chunk})::From(subchapter_node)::To(vec)
            }
        }
    }
    RETURN "Success"

QUERY search_docs_rag(query: [F64], k: I32) =>
    vecs <- SearchV<Embedding>(query, k)
    embedding_edges <- vecs::InE<EmbeddingOf>
    RETURN embedding_edges::{
        chunk: _::{chunk},
        subchapter_title: _::FromN::{title},
        subchapter_content: _::FromN::{content}
    }

QUERY create_chapter(chapter_index: I64) =>
    chapter <- AddN<Chapter>({chapter_index: chapter_index})
    RETURN chapter

QUERY get_chapter_content(chapter_index: I64) =>
    chapter <- N<Chapter>::WHERE(_::{chapter_index}::EQ(chapter_index))
    subchapters <- chapter::Out<Contains>
    RETURN subchapters::{
        title: _::{title},
        content: _::{content}
    }