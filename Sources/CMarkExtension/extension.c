#include "extension.h"
#include <parser.h>
#include <render.h>
#include <stdio.h>
#include <houdini.h>
#include <node.h>

cmark_node_type CMARK_NODE_MODULE;

static cmark_node *match(cmark_syntax_extension *self, cmark_parser *parser,
                         cmark_node *parent, unsigned char character,
                         cmark_inline_parser *inline_parser) {
    if (character != '@')
        return NULL;

    if (cmark_inline_parser_in_bracket(inline_parser, false) ||
        cmark_inline_parser_in_bracket(inline_parser, true))
        return NULL;

    if (parent->type != CMARK_NODE_PARAGRAPH)
        return NULL;

    // Get the line's remaining bytes
    cmark_chunk *chunk = cmark_inline_parser_get_chunk(inline_parser);
    int start_pos = cmark_inline_parser_get_offset(inline_parser);
    uint8_t *data = chunk->data + start_pos;
    size_t size = chunk->len - start_pos;

    // Parse up to the next `@`
    size_t content_length = 0;
    for (int i = 1; i < size; i++) {
        if (data[i] == '@') {
            content_length = i - 1;
            break;
        }
    }

    // If no `@` was found, return null
    if (content_length == 0)
        return NULL;

    // Advance the parser over what we just parsed
    cmark_inline_parser_set_offset(inline_parser, start_pos + content_length + 2);

    // Create the module node
    cmark_node *node = cmark_node_new_with_mem(CMARK_NODE_MODULE, parser->mem);
    cmark_chunk content = cmark_chunk_dup(chunk, start_pos + 1, (bufsize_t)(content_length));
    node->as.literal = content;
    cmark_node_set_syntax_extension(node, self);

    return node;
}

static const char *get_type_string(cmark_syntax_extension *extension,
                                   cmark_node *node) {
    return node->type == CMARK_NODE_MODULE ? "module" : "<unknown>";
}

static void escape_html(cmark_strbuf *dest, const unsigned char *source,
                        bufsize_t length) {
    houdini_escape_html0(dest, source, length, 0);
}

static void html_render(cmark_syntax_extension *extension,
                        cmark_html_renderer *renderer, cmark_node *node,
                        cmark_event_type ev_type, int options) {
    if (ev_type != CMARK_EVENT_ENTER)
        return;
    cmark_strbuf_puts(renderer->html, "<module>");
    escape_html(renderer->html, node->as.literal.data, node->as.literal.len);
    cmark_strbuf_puts(renderer->html, "</module>");
}

cmark_syntax_extension *create_module_syntax_extension(void) {
    cmark_syntax_extension *ext = cmark_syntax_extension_new("module");
    cmark_llist *special_chars = NULL;

    cmark_syntax_extension_set_get_type_string_func(ext, get_type_string);
    cmark_syntax_extension_set_html_render_func(ext, html_render);
    CMARK_NODE_MODULE = cmark_syntax_extension_add_node(1);

    cmark_syntax_extension_set_match_inline_func(ext, match);

    cmark_mem *mem = cmark_get_default_mem_allocator();
    special_chars = cmark_llist_append(mem, special_chars, (void *)'@');
    cmark_syntax_extension_set_special_inline_chars(ext, special_chars);

    return ext;
}
