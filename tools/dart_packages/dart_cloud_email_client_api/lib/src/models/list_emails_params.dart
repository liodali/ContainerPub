class ListEmailsParams {
  final String? query;
  final String? domain;
  final String? sort;
  final String? page;
  final String? limit;

  ListEmailsParams({this.query, this.domain, this.sort, this.page, this.limit});

  Map<String, dynamic> toQueryParameters() {
    return {
      if (query != null) 'q': query,
      if (domain != null) 'domain': domain,
      if (sort != null) 'sort': sort,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };
  }
}
