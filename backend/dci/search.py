from django.contrib.postgres.search import TrigramSimilarity
from django.db.models import Q, Value
from django.db.models.functions import Concat, Greatest

from .models import DCI


class DCISearch:

    @staticmethod
    def search(query: str):
        query = query.strip()

        if not query:
            return DCI.objects.none()

        exact = DCI.objects.filter(name__iexact=query)

        if exact.exists():
            return exact

        return (
            DCI.objects
            .annotate(similarity=TrigramSimilarity('name', query))
            .filter(similarity__gte=0.4)
            .order_by('-similarity')
        )